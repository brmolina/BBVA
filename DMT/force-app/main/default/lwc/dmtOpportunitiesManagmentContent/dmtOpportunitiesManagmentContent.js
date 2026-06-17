import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import newOpportunityModal from "c/dmtNewOpportunityModal";
import { columnsOpp } from './dmtOpportunitiesManagmentContent_Columns';
import RenewOpportunityModal from "c/dmtRenewOpportunityModal";
import { NavigationMixin } from 'lightning/navigation';
import pubsub from "omnistudio/pubsub";



// Labels
import DMT_SelectOppStatus from "@salesforce/label/c.dmt_cl_SelectOpportunityStatus_Text";
import DMT_No_Available_Opportunities from "@salesforce/label/c.DMT_No_Available_Opportunities";
import DMT_FilterResultText from "@salesforce/label/c.DMT_FilterResultText";
import DMT_SearchWithTreePointsText from "@salesforce/label/c.DMT_SearchWithTreePointsText";
import DMT_SelectStatusText from "@salesforce/label/c.DMT_SelectStatusText";
import DMT_NotFilterText from "@salesforce/label/c.DMT_NotFilterText";

// =========================================================
// Constants
// =========================================================
const NOT_FILTER_VALUE = "-notfilter-";
const NOT_FILTER_LABEL = DMT_NotFilterText;
const SEARCH_DEBOUNCE_MS = 400;
const NO_RECORDS_FLAG = "//NO RECORDS";
const ACTION_REFRESH_DATA = "REFRESH_DATA";
const PUBSUB_CHANNEL = "DMT_MarcoGeneral";
const PUBSUB_EVENT_REQUEST = "OpportunityManagement";
const FILTERS_ROOT = "opportunity";
const HAS_ACCESS_OPP_FIELD = "hasAccessOpp";
const IS_PARENT_OPP_FIELD = "isParent";
const ROLE_FUNCTIONAL_SUPPORT = "DMT_Soporte funcional";
const ROLE_CONFIGURATOR = "Configurador SF";
const CLOSED_WON = "Closed Won";
const CHUNK_SIZE = 100;
const SEARCHABLE_FIELDS = [
  "Name",
  "RecordType.Name",
  "StageName",
  "Entific__c",
  "DMT_DATE_Initial_Date__c",
  "DMT_DATE_Maturity_Date__c",
  "DMT_Client_Type__c",
  "Opportunity_Details__c"
];

export default class dmtOpportunitiesManagmentContent extends NavigationMixin(LightningElement){
  // =========================================================
  // UI / Visibility
  // =========================================================
  isLoading = false;
  labels = {
    DMT_SelectOppStatus,
    DMT_No_Available_Opportunities,
    DMT_FilterResultText,
    DMT_SearchWithTreePointsText,
    DMT_SelectStatusText
  };

  // =========================================================
  // Search
  // =========================================================
  searchText = "";
  _searchTimeout;
  searchColumnApiName = null;
  _searchIndex = new Map();

  // =========================================================
  // Filters engine (dynamic)
  // =========================================================
  filterDefs = [
    {
      key: "status",
      fieldApi: "StageName",
      valueMapPath: `${FILTERS_ROOT}.StageName`
    }
  ];
  filters = {
    status: NOT_FILTER_VALUE
  };
  picklistOptions = {
    status: [{ label: NOT_FILTER_LABEL, value: NOT_FILTER_VALUE }]
  };
  baseLabelMaps = {
    status: {}
  };

  // =========================================================
  // Data
  // =========================================================
  valuesFiltersConfig;
  tableColumns = columnsOpp;
  _tableData = [];
  filteredTableData = [];
  _indexedRecords = [];
  hasInitialized = false;
  userInformation;
  @api groupId = "";

  // =========================================================
  // API: valuesFilters
  // =========================================================
  @api
  get valuesFilters() {
    return this.valuesFiltersConfig;
  }
  set valuesFilters(value) {
    this.valuesFiltersConfig = value;
    this.buildBaseLabelMaps();
    this.rebuildAllPicklistOptions();
    this.applyFilters();
  }

  // =========================================================
  // API: userInfo
  // =========================================================
  @api
  get userInfo() {
    return this.userInformation;
  }
  set userInfo(value) {
    this.userInformation = value;
    this.tryInitializeData();
  }

  // =========================================================
  // API: isExpandedSideBar
  // =========================================================
  _expandedSideBar = "true";
  @api
  get isExpandedSideBar() {
    return this._expandedSideBar;
  }
  set isExpandedSideBar(value) {
    const v = (value ?? "").toString().trim().toLowerCase();
    if (v === "true" || v === "false") this._expandedSideBar = v;
  }

  // =========================================================
  // API: tableData
  // =========================================================
  originalTable = [];
  @api
  get tableData() {
    return this._tableData;
  }
  set tableData(value) {
    if (this.originalTable === value) {
      this.isLoading = false;
      return;
    }
    this.originalTable = value;
    this.resetFiltersAndSearch();
    this._tableData =
      Array.isArray(value) &&
      value.length > 0 &&
      value[0]?.NameURLLine !== NO_RECORDS_FLAG &&
      value[0]?.NameURL !== NO_RECORDS_FLAG
        ? value
        : [];
    this.hasInitialized = false;
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    setTimeout(() => {
      this.tryInitializeData();
    }, 0);
  }

  @api
  async handleHeaderAction(action) {
    const actionMap = {
      newOpportunity: () => this.handleNewOpportunity()
    };
    return actionMap[action]?.();
  }

  resetFiltersAndSearch() {
    this.filteredTableData = [];
    this._indexedRecords = [];
    this._searchIndex = new Map();
    this.searchText = "";
    const nextFilters = {};
    this.filterDefs.forEach((def) => {
      nextFilters[def.key] = NOT_FILTER_VALUE;
    });
    this.filters = nextFilters;
  }

  // =========================================================
  // Initialization
  // =========================================================
  async tryInitializeData() {
    const ready =
      this.userInformation &&
      Array.isArray(this._tableData) &&
      this._tableData.length > 0;

    if (!ready || this.hasInitialized) {
      this.applyFilters();
      //this.isLoading = false;

      return;
    }
    this.isLoading = true;

    this.hasInitialized = true;
    await this.handleUrlActivation();
    this.buildSearchIndex();
    this.applyFilters();
    this.isLoading = false;
  }

  // =========================================================
  // Build base labels from valuesFilters
  // =========================================================
  buildBaseLabelMaps() {
    const root = this.valuesFiltersConfig?.[FILTERS_ROOT] || {};
    const maps = {};
    this.filterDefs.forEach((def) => {
      const last = def.valueMapPath.split(".").pop();
      maps[def.key] = root?.[last] ? { ...root[last] } : {};
    });
    this.baseLabelMaps = maps;
  }
  // =========================================================
  // Url Activation con chunks — no bloquea el hilo principal
  // =========================================================
  handleUrlActivation() {
    return new Promise((resolve) => {
      const tableDataTmp = Array.isArray(this._tableData)
        ? this._tableData
        : [];
      if (!tableDataTmp.length) {
        resolve();
        return;
      }

      const canBypass = this.canBypassPermissions();
      const result = new Array(tableDataTmp.length);
      let index = 0;

      const processChunk = () => {
        const end = Math.min(index + CHUNK_SIZE, tableDataTmp.length);

        while (index < end) {
          const row = tableDataTmp[index];
          const hasAccess = row[HAS_ACCESS_OPP_FIELD];
          const isParent = row[IS_PARENT_OPP_FIELD];

          if (!hasAccess && !canBypass) {
            result[index] = {
              ...row,
              isDisabled: true,
              disableRenew: true,
              buttonClass: "notLinkAccess"
            };
          } else {
            result[index] = {
              ...row,
              isDisabled: false,
              disableRenew: !(row.StageName === CLOSED_WON && !isParent)
            };
          }
          index++;
        }

        if (index < tableDataTmp.length) {
          // eslint-disable-next-line @lwc/lwc/no-async-operation
          setTimeout(processChunk, 0);
        } else {
          this._tableData = result;
          resolve();
        }
      };

      processChunk();
    });
  }

  // =========================================================
  // Role helpers
  // =========================================================
  canBypassPermissions() {
    return (
      this.userInformation?.DMT_User_Role__c?.includes(
        ROLE_FUNCTIONAL_SUPPORT
      ) || this.userInformation?.DMT_User_Role__c?.includes(ROLE_CONFIGURATOR)
    );
  }

  // =========================================================
  // Search index — separado de los records, sin contaminar objetos
  // =========================================================
  buildSearchIndex() {
    this._searchIndex = new Map(
      this._tableData.map((r) => [r.Id, this.flattenRecord(r)])
    );
    this._indexedRecords = this._tableData;
  }

  flattenRecord(record) {
    return SEARCHABLE_FIELDS.map((field) => {
      if (field.includes(".")) {
        const [parent, child] = field.split(".");
        return record?.[parent]?.[child] ?? "";
      }
      return record?.[field] ?? "";
    })
      .join(" ")
      .toLowerCase();
  }

  valueToText(val) {
    if (val === null || val === undefined) return "";
    if (Array.isArray(val)) return val.join(" ");
    if (typeof val === "object") {
      try {
        return Object.values(val).join(" ");
      } catch (e) {
        return "";
      }
    }
    return String(val);
  }

  // =========================================================
  // Filtering pipeline
  // =========================================================
  applyFilters() {
    const hasActiveFilters = this.filterDefs.some(
      (def) =>
        this.filters[def.key] && this.filters[def.key] !== NOT_FILTER_VALUE
    );
    const hasSearch = (this.searchText || "").trim().length > 0;

    // Shortcut: sin filtros ni búsqueda — asignación directa sin coste
    if (!hasActiveFilters && !hasSearch) {
      this.filteredTableData = this._indexedRecords;
      this.rebuildAllPicklistOptions();
      return;
    }

    let rows = this._indexedRecords;

    this.filterDefs.forEach((def) => {
      const selected = this.filters[def.key];
      if (selected && selected !== NOT_FILTER_VALUE) {
        rows = rows.filter((r) => r?.[def.fieldApi] === selected);
      }
    });

    rows = this.filterBySearch(rows, this.searchText, this.searchColumnApiName);

    // Sin map ni spread — searchableText ya no existe en los objetos
    this.filteredTableData = rows;
    this.rebuildAllPicklistOptions();
  }

  filterBySearch(rows, searchKey, columnApiName) {
    const key = (searchKey || "").toLowerCase().trim();
    if (!key) return rows;

    if (columnApiName) {
      return rows.filter((r) =>
        this.valueToText(r?.[columnApiName]).toLowerCase().includes(key)
      );
    }

    return rows.filter((r) =>
      (this._searchIndex.get(r.Id) || "").includes(key)
    );
  }

  // =========================================================
  // Dynamic counts in picklist labels
  // =========================================================
  rebuildAllPicklistOptions() {
    if (!this.baseLabelMaps) return;
    const next = { ...this.picklistOptions };
    this.filterDefs.forEach((def) => {
      next[def.key] = this.buildOptionsForFilter(def);
    });
    this.picklistOptions = next;
  }

  buildOptionsForFilter(def) {
    let rows = this._indexedRecords;

    this.filterDefs.forEach((other) => {
      if (other.key === def.key) return;
      const selected = this.filters[other.key];
      if (selected && selected !== NOT_FILTER_VALUE) {
        rows = rows.filter((r) => r?.[other.fieldApi] === selected);
      }
    });

    rows = this.filterBySearch(rows, this.searchText, this.searchColumnApiName);

    const counts = this.countByField(rows, def.fieldApi);
    const base = [{ label: NOT_FILTER_LABEL, value: NOT_FILTER_VALUE }];
    const labelMap = this.baseLabelMaps?.[def.key] || {};
    const mapped = Object.entries(labelMap).map(([value, baseLabel]) => ({
      value,
      label: `${baseLabel} (${counts[value] || 0})`
    }));
    mapped.sort((a, b) => (a.label || "").localeCompare(b.label || ""));
    return [...base, ...mapped];
  }

  countByField(rows, fieldApi) {
    const out = {};
    (rows || []).forEach((r) => {
      const v = r?.[fieldApi];
      if (!v) return;
      out[v] = (out[v] || 0) + 1;
    });
    return out;
  }

  // =========================================================
  // UI handlers
  // =========================================================
  handleSearchKeyUp(event) {
    this.handleSearchInput(event);
  }

  handleSearchChange(event) {
    this.handleSearchInput(event);
  }

  handleSearchInput(event) {
    this.searchText = event.target.value || "";
    clearTimeout(this._searchTimeout);
    this._searchTimeout = setTimeout(
      () => this.applyFilters(),
      SEARCH_DEBOUNCE_MS
    );
  }

  handlePicklistChange(event) {
    const key = event.target.dataset.key;
    const value = event.detail.value;
    this.filters = { ...this.filters, [key]: value };
    clearTimeout(this._searchTimeout);
    this.applyFilters();
  }

  // =========================================================
  // Actions (Open modals)
  // =========================================================
  async handleNewOpportunity() {
    try {
      await newOpportunityModal.open({ size: "small" });
    } catch (error) {
      console.error("Error opening NewOpportunity modal:", error);
      console.error("Stack:", error?.stack);
      console.error("Message:", error?.message);
      console.error("Details:", { ...error });
    }
    return true;
  }

  async handleRenewOpportunity(event) {
    try {
      const res = await RenewOpportunityModal.open({
        size: "small",
        opportunityInfo: event.detail
      });
      if (res?.success && res?.newOppId) {
        const url = await this[NavigationMixin.GenerateUrl]({
          type: "standard__recordPage",
          attributes: {
            recordId: res.newOppId,
            objectApiName: "Opportunity",
            actionName: "view"
          }
        });

        window.open(url, "_blank");

        pubsub.fire(PUBSUB_CHANNEL, PUBSUB_EVENT_REQUEST, { action: ACTION_REFRESH_DATA });

      }
    } catch (error) {
      console.error("Error opening RenewLine modal:", error);
      console.error("Stack:", error?.stack);
      console.error("Message:", error?.message);
      console.error("Details:", { ...error });
    }
  }

  // =========================================================
  // Helpers
  // =========================================================
  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  get hasAccessActions() {
    return this.userInformation?.hasAccessActions === true;
  }

  get hasAccessWrite() {
    return this.userInformation?.hasAccessWrite;
  }
}