import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
/*import updateMultiOperationTypeFromMap from '@salesforce/apex/DMT_ConsolidatedLineService.updateMultiOperationType';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';*/

// Labels
import DMT_No_Records from '@salesforce/label/c.DMT_No_Records';
import DMT_SuccessText from '@salesforce/label/c.Success';
import DMT_TheLineText from '@salesforce/label/c.DMT_TheLineText';
import DMT_ReconnectedCorrectlyText from '@salesforce/label/c.DMT_ReconnectedCorrectlyText';
import DMT_ErrorText from '@salesforce/label/c.DMT_ErrorText';
import DMT_ErrorUpdateLineText from '@salesforce/label/c.DMT_ErrorUpdateLineText';

const DATE_FIELDS = new Set(["Start_Date__c", "End_Date__c"]);
const MONTH = {
  Jan: 0, Feb: 1, Mar: 2, Apr: 3, May: 4, Jun: 5,
  Jul: 6, Aug: 7, Sep: 8, Oct: 9, Nov: 10, Dec: 11
};

export default class DmtDealManagmentTable extends NavigationMixin(LightningElement) {
  _tableColumns = [];
  _tableData = [];
  customColumns = [];
  columnsWithInitialWidth = [];
  _expandedSideBar = "true";

  _isLoadingData = false;

  @api
  get isLoadingData() {
    return this._isLoadingData;
  }

  set isLoadingData(value) {
    const prev = this._isLoadingData;
    this._isLoadingData = value;
    if (prev === true && value === false) {
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      requestAnimationFrame(() => { this.recalculateColumns(); });
    }
  }

  labels = {
    DMT_No_Records,
    DMT_SuccessText,
    DMT_TheLineText,
    DMT_ReconnectedCorrectlyText,
    DMT_ErrorText,
    DMT_ErrorUpdateLineText
  };

  @api textNoRecords;

  // =========================================================
  // API: isExpandedSideBar
  // =========================================================
  @api
  get isExpandedSideBar() {
    return this._expandedSideBar;
  }

  _isTransitioning = false;

  set isExpandedSideBar(value) {
    if (value === this._expandedSideBar) return;

    this._expandedSideBar = value;
    this._isTransitioning = true;
    this.customColumns = this._tableColumns;

    if (this._resizeObs) this._resizeObs.disconnect();

    // eslint-disable-next-line @lwc/lwc/no-async-operation
    setTimeout(() => {
      this._isTransitioning = false;
      if (this._resizeObs) this._resizeObs.observe(this.template.host);

      if (this._tableData.length > 0 && this._tableColumns.length > 0) {
        this.buildColumnsWithContentWidth();
      }
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      requestAnimationFrame(() => { this.recalculateColumns(); });
    }, 450);
  }

  get showTable()   { return !this._isTransitioning; }
  get showLoading() { return this._isLoadingData || this._isTransitioning; }

  sortDirection = "asc";
  sortedBy;

  // =========================================================
  // API: tableColumns
  // =========================================================
  @api
  get tableColumns() {
    return this._tableColumns;
  }

  set tableColumns(v) {
    this._tableColumns = v || [];
    this.customColumns = this._tableColumns;
    this.tryInitialize();
  }

  // =========================================================
  // API: tableData
  // =========================================================
  @api
  get tableData() {
    return this._isTransitioning ? [] : this._tableData;
  }

  oldTable = [];

  set tableData(v) {
    this._measureCache = new Map();
    this._tableData = Array.isArray(v) ? v : [];

    if (this.oldTable === v) return;
    if (this._tableData.length === 0 && Array.isArray(this.oldTable) && this.oldTable.length === 0) return;

    this.oldTable = v;
    this._hasTableDataBeenSet = true;

    if (this._tableData.length === 0) {
      this.customColumns  = this._tableColumns;
      this.columnsWithInitialWidth = [];
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      setTimeout(() => { this.customTableKey = Date.now(); }, 0);
      return;
    }

    this.tryInitialize();
  }

  // =====================================================
  // Initialization guards
  // =====================================================
  _hasTableDataBeenSet = false;

  tryInitialize() {
    if (
      !Array.isArray(this._tableColumns) ||
      !this._tableColumns.length ||
      !this._hasTableDataBeenSet
    ) return;

    if (this._tableData.length === 0) {
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      setTimeout(() => {
        this.customColumns  = this._tableColumns;
        this.customTableKey = Date.now();
      }, 0);
      return;
    }

    this.customColumns  = this._tableColumns;
    this.customTableKey = Date.now();

    this.buildColumnsWithContentWidth();

    // eslint-disable-next-line @lwc/lwc/no-async-operation
    requestAnimationFrame(() => { this.recalculateColumns(); });

    Promise.resolve().then(() => this.resetTableScroll());
  }

  // =========================================================
  // Sort
  // =========================================================
  parseDate(s) {
    if (!s) return null;
    const [dd, mmm, yyyy] = s.split("-");
    const m = MONTH[mmm];
    if (m === undefined) return null;
    return Date.UTC(+yyyy, m, +dd);
  }

  onHandleSort(event) {
    const { fieldName, sortDirection } = event.detail;
    const dir    = sortDirection === "asc" ? 1 : -1;
    const isDate = DATE_FIELDS.has(fieldName);
    const data   = [...this.tableData];

    data.sort((a, b) => {
      let va = a?.[fieldName];
      let vb = b?.[fieldName];
      if (va == null || va === "") return 1;
      if (vb == null || vb === "") return -1;
      if (isDate) { va = this.parseDate(va); vb = this.parseDate(vb); }
      if (typeof va === "string") return dir * va.localeCompare(vb);
      return dir * ((va > vb) - (va < vb));
    });

    this._tableData    = data;
    this.sortDirection = sortDirection;
    this.sortedBy      = fieldName;
  }

  // =========================================================
  // Actions
  // =========================================================
  handleRowAction(event) {
    this.dispatchEvent(
      new CustomEvent("datatableactionresult", {
        detail: event.detail.row,
        bubbles: true,
        composed: true
      })
    );
  }

  handleMultiSelection(event) {
    event.stopPropagation();

    const payload = event.detail?.data || event.detail || {};

    this.dispatchEvent(
      new CustomEvent("rowselection", {
        detail: {
          context: payload.context,
          fieldName: payload.fieldName,
          value: payload.value,
          checked: payload.checked
        },
        bubbles: true,
        composed: true
      })
    );
  }

  // =========================================================
  // Column width calculation
  // =========================================================
  buildColumnsWithContentWidth() {
    const columns = this._tableColumns;
    const rows    = this._tableData;
    const MIN_W   = 30;
    const MAX_W   = 300;
    const BTN_W   = 75;
    const PAD_PX  = 30;
    const ICON_PX = 30;

    this.columnsWithInitialWidth = columns.map((col) => {
      const c = { ...col };
      if (c.type === "button") { c.initialWidth = BTN_W; return c; }

      let measureField = c.fieldName;
      if (c.type === "url" && c.typeAttributes?.label?.fieldName) {
        measureField = c.typeAttributes.label.fieldName;
      }

      let longest = (c.label ?? c.fieldName ?? "").toString();
      for (let i = 0; i < rows.length; i++) {
        const str = (rows[i]?.[measureField] ?? "").toString();
        if (str.length > longest.length) longest = str;
      }

      const px = this.measureTextDomPx(longest, PAD_PX);
      c.initialWidth = Math.max(MIN_W, Math.min(px, MAX_W));
      if (c.type === "customIconText") c.initialWidth += ICON_PX;
      return c;
    });
  }

  // =========================================================
  // DOM text measurement
  // =========================================================
  _measureCache = new Map();

  measureTextDomPx(text, paddingPx = 56) {
    const str      = (text ?? "").toString();
    const cacheKey = `${str}__${paddingPx}`;
    if (this._measureCache.has(cacheKey)) return this._measureCache.get(cacheKey);

    if (!this._measureEl) {
      const el = document.createElement("span");
      el.style.cssText = "position:absolute;left:-99999px;top:-99999px;visibility:hidden;white-space:nowrap;font-family:'Salesforce Sans',Arial,sans-serif;font-size:14px;font-weight:400";
      document.body.appendChild(el);
      this._measureEl = el;
    }

    this._measureEl.textContent = str;
    const width = Math.ceil(this._measureEl.getBoundingClientRect().width + paddingPx);
    this._measureCache.set(cacheKey, width);
    return width;
  }

  // =========================================================
  // Recalculate columns
  // =========================================================
  recalculateColumns() {
    if (
      !Array.isArray(this.columnsWithInitialWidth) ||
      !this.columnsWithInitialWidth.length ||
      !Array.isArray(this._tableColumns) ||
      !this._tableColumns.length
    ) {
      this.customColumns  = this._tableColumns;
      this.customTableKey = Date.now();
      return;
    }

    if (this._isLoadingData) {
      this.customColumns  = this._tableColumns;
      this.customTableKey = Date.now();
      return;
    }

    const isExpanded = this._expandedSideBar === "true";

    this.customColumns = isExpanded
      ? [...this.columnsWithInitialWidth]
      : [...this._tableColumns];
    this.customTableKey = Date.now();
  }

  // =========================================================
  // ResizeObserver
  // =========================================================
  _resizeObs;
  _hasResizeObserver = false;
  _resizeDebounce    = null;
  _lastContainerW    = 0;

  renderedCallback() {
    if (this._hasResizeObserver || this._isTransitioning) return;
    this._hasResizeObserver = true;

    this._resizeObs = new ResizeObserver((entries) => {
      const newW = Math.round(entries[0]?.contentRect?.width ?? 0);

      if (Math.abs(newW - this._lastContainerW) < 3) return;
      if (this._isTransitioning) return;

      clearTimeout(this._resizeDebounce);

      // eslint-disable-next-line @lwc/lwc/no-async-operation
      this._resizeDebounce = setTimeout(() => {
        if (this._isTransitioning) return;

        const finalW = Math.round(this.template.host.getBoundingClientRect().width);
        if (Math.abs(finalW - this._lastContainerW) < 3) return;

        this._lastContainerW = finalW;
        this.recalculateColumns();
      }, 50);
    });

    this._resizeObs.observe(this.template.host);
  }

  disconnectedCallback() {
    if (this._resizeObs) { this._resizeObs.disconnect(); this._resizeObs = null; }
    if (this._measureEl?.parentNode) this._measureEl.parentNode.removeChild(this._measureEl);
    this._measureEl    = null;
    this._measureCache = new Map();
  }

  // =========================================================
  // Getters
  // =========================================================
  get isEmptyTable() {
    if (this._isTransitioning) return false;
    if (this._isLoadingData === true) return false;
    return this._tableData.length === 0;
  }

  get containerWithData() {
    return this._isLoadingData === true || this._tableData.length > 0 ? "containerWithData slds-p-top_x-small" : "containerWithOutData slds-p-top_x-small";
  }

  get tableWithData() {
    return this._isLoadingData === true || this._tableData.length > 0 ? "tableWithData" : "tableWithOutData ";
  }

  resetTableScroll() {
    const el = this.template.querySelector("." + this.containerWithData);
    if (!el) return;
    el.scrollTop  = 0;
    el.scrollLeft = 0;
  }
}