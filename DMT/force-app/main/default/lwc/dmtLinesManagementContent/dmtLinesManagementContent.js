import { LightningElement, api } from "lwc";
import NewLineModal from "c/dmtNewLineModal";
import RenewLineModal from "c/dmtRenewLineModal";
import pubsub from "omnistudio/pubsub";
import consumptionReassign from "@salesforce/apex/DMT_Utils.consumptionReassign";
import processLines from "@salesforce/apex/DMT_LinesBulkActionController.processLines";
import ModifyLinesModal from "c/dmt_modify_modal";
import getAutoByLineIds from "@salesforce/apex/DMT_LinesBulkActionController.getAutoByLineIds";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { columsLine } from "./dmtLinesManagementContent_Colums";
import hasNotApprovalRequired from '@salesforce/customPermission/DMT_Not_Approval_Required';
import hasGodPermission from '@salesforce/customPermission/DMT_Line_God';

// Labels
import DMT_SelectLineType from "@salesforce/label/c.dmt_cl_SelectLineType_Text";
import DMT_SelectLineStatus from "@salesforce/label/c.dmt_cl_SelectLineStatus_text";
import DMT_RecalculationErrorMessage from "@salesforce/label/c.dmt_cl_toastRecalculationErrorMessage";
import DMT_RecalculationSuccessMessage from "@salesforce/label/c.dmt_cl_toastRecalculationSuccessMessage";
import DMT_No_Available_Lines from "@salesforce/label/c.DMT_No_Available_Lines";

// =========================================================
// Constants
// =========================================================
const NOT_FILTER_VALUE = "-notfilter-";
const NOT_FILTER_LABEL = "Not Filter";
const SEARCH_DEBOUNCE_MS = 400;
const NO_RECORDS_FLAG = "//NO RECORDS";
const FILTERS_ROOT = "line";
const ROLE_FUNCTIONAL_SUPPORT = "DMT_Soporte funcional";
const ROLE_CONFIGURATOR = "Configurador SF";
const ROLE_READONLY = "DMT_Read Only";
const ROLE_READONLYLINES = "DMT_OnlyLines";
const STATUS_CLOSED = "Closed";
const CLOSED_WON = "Won";
const STATUS_DRAFT = "Draft";
const HAS_ACCESS_LINES_FIELD = "hasAccessLine";
const IS_PARENT_LINES_FIELD = "isParent";
const CHUNK_SIZE = 100;
const SEARCHABLE_FIELDS = [
  "Name",
  "Product__c",
  "Status__c",
  "Booking_Geography__c",
  "Start_Date__c",
  "End_Date__c",
  "Client_Type__c",
  "Line_Details__c",
  "Line_Id__c"
];

export default class dmtLinesManagementContent extends LightningElement {
  // =========================================================
  // UI / Visibility
  // =========================================================
  isLoading = false;
  isLoadingRecualculate = false;
  labels = {
    DMT_RecalculationErrorMessage,
    DMT_SelectLineStatus,
    DMT_RecalculationSuccessMessage,
    DMT_SelectLineType,
    DMT_No_Available_Lines
  };
  hasConnectPermission = hasNotApprovalRequired;
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
      key: "type",
      fieldApi: "Product__c",
      valueMapPath: `${FILTERS_ROOT}.Product__c`
    },
    {
      key: "status",
      fieldApi: "Status__c",
      valueMapPath: `${FILTERS_ROOT}.Status__c`
    }
  ];
  filters = {
    type: NOT_FILTER_VALUE,
    status: NOT_FILTER_VALUE
  };
  picklistOptions = {
    type: [{ label: NOT_FILTER_LABEL, value: NOT_FILTER_VALUE }],
    status: [{ label: NOT_FILTER_LABEL, value: NOT_FILTER_VALUE }]
  };
  baseLabelMaps = {
    type: {},
    status: {}
  };

  // =========================================================
  // Data
  // =========================================================
  valuesFiltersConfig;
  tableColumns = [];
  _tableData = [];
  filteredTableData = [];
  _indexedRecords = [];
  hasInitialized = false;
  @api groupId;
  @api clientId;
  @api taxpayer;
  userInformation;

  connectedCallback() {
    this.baseTableColumns = this.buildVisibleColumns({ hideRenew: false });
    this.tableColumns = this.baseTableColumns;
  }

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

  @api
  async handleHeaderAction(action) {
    const actionMap = {
      newLine: () => this.handleNewLine(),
      recalculateApprovals: () => this.handleRecalculateApprovals()
    };
    return actionMap[action]?.();
  }

  // =========================================================
  // Initialization
  // =========================================================
  async tryInitializeData() {
    const ready =
      this.userInformation?.DMT_User_Role__c &&
      Array.isArray(this._tableData) &&
      this._tableData.length > 0 &&
      Array.isArray(this.tableColumns) &&
      this.tableColumns.length > 0;

    if (!ready || this.hasInitialized) {
      this.applyFilters();
      return;
    }
    this.isLoading = true;

    this.hasInitialized = true;
    await this.handleUrlActivation();
    this.buildSearchIndex();
    this.applyFilters();
    this.loadAutoValues();
    this.isLoading = false;
  }

  // =========================================================
  // Role helpers
  // =========================================================
  canBypassPermissions() {
    return (
      this.userInformation?.DMT_User_Role__c?.includes(
        ROLE_FUNCTIONAL_SUPPORT
      ) || this.userInformation?.DMT_User_Role__c?.includes(ROLE_CONFIGURATOR)
      || this.userInformation?.DMT_User_Role__c?.includes(ROLE_READONLY)
      || this.userInformation?.DMT_User_Role__c?.includes(ROLE_READONLYLINES)
    );
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
          const hasAccessLines = row[HAS_ACCESS_LINES_FIELD];
          const isParent = row[IS_PARENT_LINES_FIELD];
          const noPermisos = !hasAccessLines && !canBypass;

          if (noPermisos) {
            result[index] = {
              ...row,
              isDisabled: true,
              disableRenew: true,
              buttonClass: "notLinkAccess"
            };
          } else {
            const canRenew =
              row.Status__c === STATUS_CLOSED &&
              row.Closed__c === CLOSED_WON &&
              !isParent;
            result[index] = {
              ...row,
              isDisabled: false,
              disableRenew: !canRenew
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
  async handleRenewLine(event) {
    try {
      await RenewLineModal.open({
        size: "small",
        lineId: event.detail.Id
      });
    } catch (error) {

    }
  }

  async handleNewLine() {
    try {
      const resultId = await NewLineModal.open({
        size: "small",
        clientId: this.clientId,
        groupId: this.groupId,
        taxPayer: this.taxpayer,
      });
      if (resultId) {
        this.dispatchEvent(new CustomEvent('refreshdata', {
              bubbles: true,     // Permite que el evento suba en el árbol DOM
              composed: true     // Permite que cruce la barrera del Shadow DOM
          }));
      }
    } catch (error) {

    }

    return true;
  }

  // =========================================================
  // Get auto
  // =========================================================
  async loadAutoValues() {
    if (!hasNotApprovalRequired) {
      return;
    }
    const lineIds = (this._indexedRecords || [])
      .map((r) => r.Line_Id__c)
      .filter((id) => !!id);

    if (!lineIds.length) return;

    try {
      const autoMap = await getAutoByLineIds({ lineIds });

      this._indexedRecords = (this._indexedRecords || []).map((row) => ({
        ...row,
        auto: autoMap[row.Line_Id__c] ?? false
      }));

      this.applyFilters();

    } catch (error) {
    }
  }

  // =========================================================
  // Helpers
  // =========================================================
  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  get showSpinner() {
    return this.isLoadingRecualculate;
  }

  get hasAccessActions() {
    return this.userInformation?.hasAccessActions;
  }

  get hasAccessWrite() {
    return this.userInformation?.hasAccessWrite;
  }

// =========================================================
// Bulk action / selection state
// =========================================================
currentBulkAction = null;
selectionMode = false;
selectedRows = [];
baseTableColumns = [];

isRenewColumn(column) {
  return (
    column?.type === "button-icon" &&
    (column?.typeAttributes?.name === "Renew" || column?.label === "Renew")
  );
}

isAutoColumn(column) {
  return column?.fieldName === "auto";
}

buildVisibleColumns({ hideRenew = false } = {}) {
  return (columsLine || []).filter((column) => {
    if (!hasNotApprovalRequired && this.isAutoColumn(column)) {
      return false;
    }

    if (hideRenew && this.isRenewColumn(column)) {
      return false;
    }

    return true;
  });
}

get hasActiveBulkAction() {
  return !!this.currentBulkAction;
}

get showConnectAction() {
  return (
    this.hasConnectPermission &&
    (!this.currentBulkAction || this.currentBulkAction === "connect")
  );
}

get showDisconnectAction() {
  return (
    this.hasConnectPermission &&
    (!this.currentBulkAction || this.currentBulkAction === "disconnect")
  );
}

get showRenewAction() {
  return !this.currentBulkAction || this.currentBulkAction === "renew";
}

get disableConnectAction() {
  return this.currentBulkAction === "connect";
}

get disableDisconnectAction() {
  return this.currentBulkAction === "disconnect";
}

get disableRenewAction() {
  return this.currentBulkAction === "renew";
}

get showModifyAction() {
  return !this.currentBulkAction || this.currentBulkAction === "modify";
}

get disableModifyAction() {
  return this.currentBulkAction === "modify";
}

get showRenewAndModifyAction() {
  return this.currentBulkAction === "renew";
}

get selectableRows() {
  return (this.filteredTableData || []).filter((row) => row.bulkSelectable);
}

get allSelectableRowsSelected() {
  const selectable = this.selectableRows;
  return selectable.length > 0 && selectable.every((row) => row.bulkSelected);
}

get hasSelectableRows() {
  return this.selectableRows.length > 0;
}

get disableSelectAllButton() {
  return !this.hasSelectableRows;
}

get showSelectAllLink() {
  return this.hasSelectableRows && !this.allSelectableRowsSelected;
}

get showUnselectAllLink() {
  return this.hasSelectableRows && this.allSelectableRowsSelected;
}

get selectAllLabel() {
  return this.allSelectableRowsSelected ? "Unselect all" : "Select all";
}

// =========================================================
// Add selectable column dynamically
// =========================================================
enableSelectionColumn() {
  if (this.selectionMode) {
    return;
  }

  this.selectionMode = true;

  const selectionColumn = {
    label: "",
    fieldName: "bulkSelected",
    type: "customselectRow",
    hideDefaultActions: true,
    cellAttributes: {
      style: "text-align: center;"
    },
    typeAttributes: {
      aviableItem: { fieldName: "bulkSelectable" },
      checkedItem: { fieldName: "bulkSelected" },
      fieldName: "bulkSelected",
      context: { fieldName: "Id" }
    }
  };

  const columnsWithoutInlineRenew = this.buildVisibleColumns({ hideRenew: true });
  this.tableColumns = [selectionColumn, ...columnsWithoutInlineRenew];
}

disableSelectionColumn() {
  this.selectionMode = false;
  this.baseTableColumns = this.buildVisibleColumns({ hideRenew: false });
  this.tableColumns = this.baseTableColumns;
}

// =========================================================
// Prepare rows for selection column
// =========================================================
decorateRowsForBulkSelection(rows, predicate = () => true) {
  return (rows || []).map((row) => ({
    ...row,
    bulkSelectable: predicate(row),
    bulkSelected: false
  }));
}

// =========================================================
// Handle checkbox selection coming from custom datatable
// =========================================================
handleSelection(event) {
  const { context, fieldName, value, checked } = event.detail || {};
  const targetField = fieldName || "bulkSelected";
  const nextValue = value ?? checked ?? false;

  this.filteredTableData = (this.filteredTableData || []).map((row) =>
    row.Id === context
      ? {
          ...row,
          [targetField]: nextValue
        }
      : row
  );

  this.updateSelectedRows();
}

updateSelectedRows() {
  this.selectedRows = (this.filteredTableData || []).filter(
    (row) => row.bulkSelected
  );
}

handleSelectAll() {
  this.filteredTableData = (this.filteredTableData || []).map((row) => {
    if (!row.bulkSelectable) {
      return row;
    }
    return {
      ...row,
      bulkSelected: true
    };
  });

  this.updateSelectedRows();
}

handleUnselectAll() {
  this.filteredTableData = (this.filteredTableData || []).map((row) => {
    if (!row.bulkSelectable) {
      return row;
    }
    return {
      ...row,
      bulkSelected: false
    };
  });

  this.updateSelectedRows();
}

// =========================================================
// Dispatcher
// =========================================================
handleAction(event) {
  const action = event.currentTarget?.dataset?.action;

  const actionMap = {
    connect: () => this.prepareConnect(),
    disconnect: () => this.prepareDisconnect(),
    renew: () => this.prepareRenew(),
    modify: () => this.prepareModify()
  };

  const handler = actionMap[action];

  if (!handler) {
    this.showToast("Warning", `Acción no soportada: ${action}`, "warning");
    return;
  }

  this.currentBulkAction = action;
  this.enableSelectionColumn();
  this.selectedRows = [];

  try {
    handler();
  } catch (error) {
    this.showToast(
      "An error has occurred",
      error?.body?.message || error?.message || "Unknown error",
      "error"
    );
  }
}

// =========================================================
// CONNECT
// Filtra visualmente la tabla a Closed + Won
// y deja seleccionables esas filas
// =========================================================
prepareConnect() {
  this.enableSelectionColumn();
  this.currentBulkAction = "connect";

  this.filteredTableData = (this._indexedRecords || [])
    .filter((line) => {

      const hasAccessValidation = hasGodPermission
        ? true
        : line?.hasAccessLine === true;

      return (
        line?.Status__c === STATUS_CLOSED &&
        line?.Closed__c === CLOSED_WON &&
        line?.auto === false &&
        line?.Product__c === "Line" &&
        hasAccessValidation
      );
    })
    .map((row) => ({
      ...row,
      bulkSelected: false,
      bulkSelectable: true
    }));

  this.selectedRows = [];
}

// =========================================================
// DISCONNECT
// =========================================================

prepareDisconnect() {
    this.enableSelectionColumn();
    this.currentBulkAction = "disconnect";


    this.filteredTableData = (this._indexedRecords || [])
      .filter((line) => {

        const hasAccessValidation = hasGodPermission
          ? true
          : line?.hasAccessLine === true;

        return (
          line?.Status__c === STATUS_CLOSED &&
          line?.Closed__c === CLOSED_WON &&
          line?.auto === true &&
          line?.Product__c === "Line" &&
          hasAccessValidation
        );
      })
      .map((row) => ({
        ...row,
        bulkSelected: false,
        bulkSelectable: true
      }));

    this.selectedRows = [];
}

// =========================================================
// RENEW
// =========================================================
prepareRenew() {
  this.enableSelectionColumn();
    this.currentBulkAction = "renew";

    this.filteredTableData = (this._indexedRecords || [])
      .filter((line) => 
        line?.disableRenew === false
      )
      .map((row) => ({
        ...row,
        bulkSelected: false,
        bulkSelectable: true
      }));

    this.selectedRows = [];
}

// =========================================================
// MODIFY
// =========================================================
prepareModify() {
  this.enableSelectionColumn();
  this.currentBulkAction = "modify";

  this.filteredTableData = (this._indexedRecords || [])
    .filter((line) => {
      const hasAccessValidation = hasGodPermission
        ? true
        : line?.hasAccessLine === true;

      return (
        line?.Status__c === STATUS_DRAFT &&
        hasAccessValidation
      );
    })
    .map((row) => ({
      ...row,
      bulkSelected: false,
      bulkSelectable: true
    }));

  this.selectedRows = [];
}

get bulkActionLabel() {
  const map = {
    connect: "Connect",
    disconnect: "Disconnect",
    renew: "Renew",
    modify: "Modify"
  };

  return map[this.currentBulkAction] || "Apply";
}

// =========================================================
// Final execution methods
// =========================================================
  async executeBulkAction() {
    if (!this.selectedRows?.length) {
      this.showToast("Warning", "Please select at least one line", "warning");
      return;
    }

      if (this.currentBulkAction === "modify") {
        await this.openModifyModal();
        return;
      }

    const lineIds = this.selectedRows
      .map((r) => r.Line_Id__c)
      .filter((id) => !!id);

    try {
      this.isLoading = true;
      await processLines({
        lineIds,
        actionType: this.currentBulkAction
      });

      this.showToast(
        "Success",
        `${this.bulkActionLabel} executed successfully`,
        "success"
      );
      this.loadAutoValues();
      
      pubsub.fire("DMT_MarcoGeneral", "LineManagement", {
      action: "REFRESH_DATA"
      });
      this.isLoading = false;
      this.selectionMode = false;
      this.currentBulkAction = null;
      this.selectedRows = [];

      // Quitar columna de selección
      this.tableColumns = this.baseTableColumns;

    } catch (error) {
      this.handleCancelSelection(); // reset automático
      this.isLoading = false;
      this.showToast(
        "Error",
        error?.body?.message || error?.message || "Unknown error",
        "error"
      );
    }
  }

  handleCancelSelection() {
    this.selectionMode = false;
    this.currentBulkAction = null;
    this.selectedRows = [];

    // Quitar columna de selección
    this.tableColumns = this.baseTableColumns;

    // Restaurar datos originales
    this.filteredTableData = this._indexedRecords;
  }

async handleRenew() {
  const rows = (this.filteredTableData || []).filter((row) => row.bulkSelected);

  if (!rows.length) {
    this.showToast(
      "Warning",
      "Debes seleccionar al menos una línea",
      "warning"
    );
    return;
  }


  // TODO: llamada Apex
}

async handleModify() {
  const rows = (this.filteredTableData || []).filter((row) => row.bulkSelected);

  if (!rows.length) {
    this.showToast(
      "Warning",
      "Debes seleccionar al menos una línea",
      "warning"
    );
    return;
  }


  // TODO: llamada Apex
}

handleMenuAction(event) {
  this.handleAction({
    currentTarget: {
      dataset: {
        action: event.detail.value
      }
    }
  });
}

async openModifyModal() {
  try {
    const selectedLineIds = this.selectedRows
    
      .map((r) => r.Line_Id__c)
      .filter((id) => !!id);

    const result = await ModifyLinesModal.open({
      size: "medium",
      lineIds: selectedLineIds,
      selectedRows: this.selectedRows
    });

    if (result === "saved") {
      this.showToast(
        "Success",
        "Lines modified successfully",
        "success"
      );

      this.handleCancelSelection();

      pubsub.fire("DMT_MarcoGeneral", "LineManagement", {
        action: "REFRESH_DATA"
      });
    }
  } catch (error) {
    this.showToast(
      "Error",
      error?.body?.message || error?.message || "Unknown error",
      "error"
    );
  }
}

  async executeRenewAndModify() {
    if (!this.selectedRows?.length) {
      this.showToast("Warning", "Please select at least one line", "warning");
      return;
    }

    const lineIds = this.selectedRows
      .map((r) => r.Line_Id__c)
      .filter((id) => !!id);

    try {
      this.isLoading = true;

      const result = await processLines({
        lineIds,
        actionType: "renew"
      });

      const newLineIds = result?.newLineIds || [];

      if (!newLineIds.length) {
        throw new Error("Renew finished but no new lines were returned.");
      }

      this.isLoading = false;

      const modalResult = await ModifyLinesModal.open({
        size: "large",
        lineIds: newLineIds
      });

      if (modalResult === "saved") {
        this.showToast(
          "Success",
          "Lines renewed and modified successfully",
          "success"
        );
      } else {
        this.showToast(
          "Success",
          "Lines renewed successfully",
          "success"
        );
      }

      this.handleCancelSelection();

      pubsub.fire("DMT_MarcoGeneral", "LineManagement", {
        action: "REFRESH_DATA"
      });

    } catch (error) {
      this.showToast(
        "Error",
        error?.body?.message || error?.message || "Unknown error",
        "error"
      );
    } finally {
      this.isLoading = false;
    }
  }

  get selectAllHeaderIcon() {
    return this.allSelectableRowsSelected
      ? "utility:check"
      : "utility:add";
  }

  get selectAllHeaderTitle() {
    return this.allSelectableRowsSelected
      ? "Unselect all"
      : "Select all";
  }

  get selectAllHeaderClass() {
    return this.allSelectableRowsSelected
      ? "fake-select-all-header is-selected"
      : "fake-select-all-header";
  }
  
  handleToggleSelectAll() {
    if (this.allSelectableRowsSelected) {
      this.handleUnselectAll();
    } else {
      this.handleSelectAll();
    }
  }

  get showMoreActionsMenu() {
    return (
      this.hasConnectPermission &&
      (
        this.showConnectAction ||
        this.showDisconnectAction
      )
    );
  }

    // =========================================================
  // Recalculate approvals (Apex)
  // =========================================================
  async handleRecalculateApprovals() {
    this.isLoadingRecualculate = true;
    try {
      const response = await consumptionReassign({
        inputMap: { groupId: this.groupId }
      });
      if (response === "OK") {
        this.showToast(
          "Success!",
          this.labels.DMT_RecalculationSuccessMessage,
          "success"
        );
        
      }else{
        this.showToast(
          "An error has occurred",
          this.labels.DMT_RecalculationErrorMessage,
          "error"
        );
      }
    } catch (e) {
      const msg = e?.body?.message || e?.message || "Unknown error";
      this.showToast("An error has occurred", msg, "error");
    } finally {
      this.isLoadingRecualculate = false;
}
  return true;
}

}