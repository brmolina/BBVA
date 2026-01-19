import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { FlexCardMixin } from 'omnistudio/flexCardMixin';
import Id from '@salesforce/user/Id';
import ProfileName from '@salesforce/schema/User.Profile.Name';
import DMT_User_Role__c from '@salesforce/schema/User.DMT_User_Role__c';
import { loadStyle } from 'lightning/platformResourceLoader';
import datatablestyles from '@salesforce/resourceUrl/ButtonDatatableCss';
import { NavigationMixin } from 'lightning/navigation';

import DMT_No_Records from '@salesforce/label/c.DMT_No_Records';
import DMT_No_Available_Opportunities from '@salesforce/label/c.DMT_No_Available_Opportunities';
import DMT_No_Available_Lines from '@salesforce/label/c.DMT_No_Available_Lines';

const FIELD_START_DATE = 'Start_Date__c';
const FIELD_END_DATE = 'End_Date__c';
const NO_RECORDS_FLAG = '//NO RECORDS';

export default class MyTableComponent extends FlexCardMixin(NavigationMixin(LightningElement)) {
  // ---------------------------
  // DATA
  // ---------------------------
  info = [];
  labels = {
    DMT_No_Records,
    DMT_No_Available_Opportunities,
    DMT_No_Available_Lines
  };

  // ---------------------------
  // COLUMNS (SEPARADAS)
  // ---------------------------
  baseColumns = [];        // columnas originales que llegan
  customAutoCols = [];     // copia con initialWidth (solo custom)
  customColumns = [];      // columnas aplicadas realmente
  customTableKey = Date.now();
  columnWidthsMode = 'auto';

  // compat template actual
  colString;
  originalInfo;

  // ---------------------------
  // API / STATE
  // ---------------------------

  hideCheckbox;
  showTable = true;
  activeFilters = [];

  teamMembers;
  userProfileName;
  userDMTRoles;
  userId = Id;
  linesParents;

  @track isLoading = false;

  newSelectedClientId;
  oldSelectedClientId;
  newTabChange;
  oldTabChange = "";

  labelNoRecordTable;

  _customCanvas;
  _customCtx;
  _autofitScheduled = false; 

  // ---------------------------
  // USER / PROFILE
  // ---------------------------
  @wire(getRecord, { recordId: Id, fields: [ProfileName, DMT_User_Role__c] })
  userDetails({ error, data }) {
    if (data?.fields?.Profile?.value) {
      this.userProfileName = data.fields.Profile.value.fields.Name.value;
      this.userDMTRoles = data.fields.DMT_User_Role__c.value;

      if (this.userProfileName && this.info?.length > 0 && this.teamMembers && this.linesParents) {
        this.handleUrlActivation();
      }
    }
  }


  connectedCallback() {
    loadStyle(this, datatablestyles);
  }

  // ---------------------------
  // API GETTERS/SETTERS
  // ---------------------------
  @api
  get showTableName() {
    return this.showTable;
  }
  set showTableName(value) {
    this.showTable = value?.toLowerCase() === 'true';
  }

  @api
  get labelNorecords() {
    return this.labelNoRecordTable;
  }
  set labelNorecords(value) {
    this.labelNoRecordTable = value;
  }

  @api
  get hideCheckboxName() {
    return this.hideCheckbox;
  }
  set hideCheckboxName(value) {
    this.hideCheckbox = value?.toLowerCase() === 'true';
  }

  @api
  get selectedClient() {
    return this.newSelectedClientId;
  }
  set selectedClient(value) {
    this.newSelectedClientId = value;
    this.activeFilters = [];
    this.resetTableScroll();
  }

  @api
  get changeTab() {
    return this.newTabChange;
  }
  set changeTab(value) {
    this.newTabChange = value;
    if (this.oldTabChange !== this.newTabChange) {
      this.oldTabChange = this.newTabChange;
      if(this.oldTabChange !== "" && this.info?.length > 0 && this.baseColumns?.length > 0){
        this._autofitScheduled = false;
        this.enableAutoMode();
      }

    }
  }

  @api
  get infoName() {
    return this.info;
  }
  set infoName(value) {
    this.isLoading = true;

    // normalizar info
    this.info =
      Array.isArray(value) &&
      value.length > 0 &&
      (value[0]?.NameURLLine !== NO_RECORDS_FLAG && value[0]?.NameURL !== NO_RECORDS_FLAG)
        ? value
        : [];
    
    
    this._autofitScheduled = false;
    this.enableAutoMode();

    if (this.userProfileName && this.info?.length > 0 && this.teamMembers && this.linesParents) {
      this.handleUrlActivation();
    }

    this.originalInfo = this.info;
    this.applyAllFiltersToInfo();

    this.isLoading = false;
  }

  @api
  get colName() {
    return this.colString;
  }
  set colName(value) {
    this.baseColumns = Array.isArray(value) ? value : [];
    this.colString = this.baseColumns;
    this.customColumns = this.baseColumns;
    this.customAutoCols = this.baseColumns;
    if(this.info && this.info.length > 0){ 
    this._autofitScheduled = false;
    this.enableAutoMode();

    }
  }

  @api
  get teamMember() {
    return this.teamMembers;
  }
  set teamMember(value) {
    this.teamMembers = value;

    if (this.userProfileName && this.info?.length > 0 && this.teamMembers?.length > 0) {
      this.handleUrlActivation();
    }
  }

  @api
  get lineParents() {
    return this.linesParents;
  }
  set lineParents(value) {
    this.linesParents = value;

    if (this.userProfileName && this.info?.length > 0 && this.teamMembers && this.linesParents) {
      this.handleUrlActivation();
    }
  }
  _selectedFilter;

  @api
  get selectFilteredAndColumn() {
    return this._selectedFilter;
  }
  set selectFilteredAndColumn(value) {
    this._selectedFilter = value;

    
    const el = this.template.querySelector('[data-id="dtScroll"]');
    if (el) el.scrollTop = 0;
    

    const filterObj = this.parseSelectedFilter(value);
    console.log('JACG', JSON.stringify(filterObj));

   

    if (!filterObj){
      this.info = this.originalInfo;
      this.activeFilters = [];
       return;
    } 
    this.isLoading = true;
    this.upsertFilterInList(filterObj);
    this.applyAllFiltersToInfo();
    this.enableAutoMode();
     console.log('JACG', JSON.stringify(this.activeFilters));
    this.isLoading = false;
  }

  parseSelectedFilter(raw) {
    // raw ejemplo:  "filter":"Treasury Line","column":"Product__c"
    if (!raw) return null;

    try {
      const obj = JSON.parse('{' + raw + '}');

      const column = obj?.column?.toString().trim();
      const filter = (obj?.filter ?? '').toString().trim();

      if (!column) return null;

      return { column, filter };
    } catch (e) {
      console.warn('Invalid filter format:', raw, e);
      return null;
    }
  }

  upsertFilterInList({ column, filter }) {
  this.activeFilters = Array.isArray(this.activeFilters) ? this.activeFilters : [];

  const idx = this.activeFilters.findIndex(f => f.column === column);

  // si filter vacío => eliminar
  if (!filter) {
    if (idx !== -1) {
      const updated = [...this.activeFilters];
      updated.splice(idx, 1);
      this.activeFilters = updated;
    }
    return;
  }

  // insertar o actualizar
  if (idx === -1) {
    this.activeFilters = [...this.activeFilters, { column, filter }];
    return;
  }

  if (this.activeFilters[idx].filter !== filter) {
    const updated = [...this.activeFilters];
    updated[idx] = { column, filter };
    this.activeFilters = updated;
  }
}

  applyAllFiltersToInfo() {
    const base = this.originalInfo;
    const filters = this.activeFilters;

    // Si no hay filtros => tabla completa
    if (!filters || filters.length === 0) {
      this.info = base;
      return;
    }

    // AND: debe cumplir TODOS los filtros
    const results = base.filter(row =>
      filters.every(f => row?.[f.column] === f.filter)
    );

    // Si hay filtros y no hay resultados => tabla vacía (NO reset)
    this.info = results;
  }
  


   async enableAutoMode() {
    if (this._autofitScheduled) return;

    this._autofitScheduled = true;
    // 1) Compute column widths using FIXED mode with initialWidth
     await this.applyWidthsByContent();

    // 2) Wait for the DOM to render with the new widths
     await this.nextFrame();

    // 3) Restore original column definitions and switch back to AUTO mode
    this.customColumns = this.baseColumns;
    this.columnWidthsMode = "auto";

  }


  async applyWidthsByContent() {
    const maxColumnWidth = 500;
    const minColumnWidth = 90;
    const rows = Array.isArray(this.info) ? this.info : [];


// 1) Compute base width per column based on longest text (label or cell value)
    let newCols = (this.baseColumns || []).map(col => {
        const c = { ...col };

        // Field to measure (special case for URL label)
        let measureField = c.fieldName;
        if (c.type === 'url' && c.typeAttributes?.label?.fieldName) {
            measureField = c.typeAttributes.label.fieldName;
        }

        if (c.type === 'button') {
            c.initialWidth = 120;
            return c;
        }

        // Start with the column label; compare against all row values
        let longestValue = (c.label ?? c.fieldName ?? '').toString();
        for (const row of rows) {
            const raw = row?.[measureField];
            const str = (raw ?? '').toString();
            if (str.length > longestValue.length) {
                longestValue = str;
            }
        }

        // Convert text length to pixel width and clamp to min/max
        const px = this.measureTextPx(longestValue);
        c.initialWidth = Math.max(minColumnWidth, Math.min(px, maxColumnWidth));
        return c;
    });
    this.customAutoCols = newCols;
    this.customColumns = this.customAutoCols;
    this.columnWidthsMode = 'fixed';
    this.tableKey = Date.now();
    await this.nextFrame();
  }
  nextFrame() {
    // Resolves on the next browser rendering frame
    return new Promise(resolve => requestAnimationFrame(resolve));
  }
  measureTextPx(text) {
    const str = (text ?? '').toString();

    if (!this._customCanvas) {
      this._customCanvas = document.createElement('canvas');
      this._customCtx = this._customCanvas.getContext('2d');
      this._customCtx.font = '14px "Salesforce Sans", Arial, sans-serif';
    }

    const metrics = this._customCtx.measureText(str);
    const cellPadding = 40;

    return Math.ceil(metrics.width + cellPadding);
  }


  handleUrlActivation() {
    let infoAux = JSON.parse(JSON.stringify(this.info));

    for (let i = 0; i < infoAux.length; i++) {
      let foundMemb = null;

      if (
        this.teamMembers &&
        this.teamMembers !== '' &&
        !(typeof this.teamMembers === 'string' || this.teamMembers instanceof String)
      ) {
        foundMemb = this.teamMembers.find((element) => element.LineId == infoAux[i].Id);
      }

      let foundMembParent = null;

      if (
        this.linesParents &&
        this.linesParents !== '' &&
        !(typeof this.linesParents === 'string' || this.linesParents instanceof String)
      ) {
        foundMembParent = this.linesParents.find(
          (element) => element.DMT_Parent_Line__c == infoAux[i].Id
        );
      }

      if (
        !foundMemb &&
        infoAux[i].OwnerId != this.userId &&
        !(infoAux[i].DMT_Origin__c == 'AMIWEB' && infoAux[i].Product__c == 'Risk Approval') &&
        !this.userDMTRoles?.includes('DMT_Soporte funcional') &&
        !this.userDMTRoles?.includes('Configurador SF')
      ) {
        infoAux[i].isDisabled = true;
        infoAux[i].button = true;
        infoAux[i].buttonClass = 'buttonDisabled';
      } else if (infoAux[i].NameURLLine == '//NO RECORDS') {
        infoAux[i].Name = '//NO RECORDS';
        infoAux[i].isDisabled = true;
        infoAux[i].button = true;
        infoAux[i].buttonClass = 'buttonDisabled';
      } else if (
        infoAux[i].Status__c != 'Closed' ||
        (infoAux[i].Product__c == 'Treasury Line' && foundMembParent) ||
        infoAux[i].DMT_Cancel__c ||
        (infoAux[i].Product__c == 'Line' && foundMembParent)
      ) {
        infoAux[i].button = true;
      }
    }

    this.info = JSON.parse(JSON.stringify(infoAux));
  }

  handleRowAction(event) {
    const action = event.detail.action;

    if (action.actionName == 'goToRecord') {
      const row = event.detail.row;

      this[NavigationMixin.GenerateUrl]({
        type: 'standard__recordPage',
        attributes: {
          recordId: row.Id,
          objectApiName: 'DMT_Line__c',
          actionName: 'view'
        }
      }).then((url) => window.open(url, '_blank'));
    } else {
      const row = event.detail.row;

      this.dispatchEvent(
        new CustomEvent('renewline', {
          bubbles: true,
          composed: true,
          detail: row.Id
        })
      );
    }
  }

  handleSort(event) {
    this.sortBy = event.detail.fieldName;
    this.sortDirection = event.detail.sortDirection;
    this.sortData(event.detail.fieldName, event.detail.sortDirection);
  }

  parseDdMonYyyy(stringValue) {
    if (!stringValue) return null;

    const [ddStr, monStr, yyyyStr] = stringValue.split('-');
    const dd = parseInt(ddStr, 10);
    const yyyy = parseInt(yyyyStr, 10);

    const monthMap = {
      jan: 0,
      feb: 1,
      mar: 2,
      apr: 3,
      may: 4,
      jun: 5,
      jul: 6,
      aug: 7,
      sep: 8,
      oct: 9,
      nov: 10,
      dec: 11
    };

    const mm = monthMap[monStr?.toLowerCase()];
    if (isNaN(dd) || isNaN(yyyy) || mm == null) return null;

    return Date.UTC(yyyy, mm, dd);
  }

  sortData(fieldname, direction) {
    const parseData = JSON.parse(JSON.stringify(this.info));
    const isReverse = direction === 'asc' ? 1 : -1;

    parseData.sort((a, b) => {
      let x = a[fieldname];
      let y = b[fieldname];

      if (fieldname === FIELD_START_DATE || fieldname === FIELD_END_DATE) {
        x = x ? this.parseDdMonYyyy(x) : null;
        y = y ? this.parseDdMonYyyy(y) : null;
      }

      if (x == null && y == null) return 0;
      if (x == null) return 1 * isReverse;
      if (y == null) return -1 * isReverse;

      if (x > y) return 1 * isReverse;
      if (x < y) return -1 * isReverse;

      return 0;
    });

    this.info = parseData;
  }

  // ---------------------------
  // GETTERS
  // ---------------------------
  get containerWithData() {
    return this.info.length > 0 ? 'containerWithData' : 'containerWithOutData';
  }

  get tableWithData() {
    return this.info.length > 0 ? 'tableWithData' : 'tableWithOutData ';
  }

  get isEmptyTable() {
    return this.info.length > 0 ? false : true;
  }

  get textoNoAvailableRecords() {
    return this.newTabChange === 'Lines'
      ? this.labels.DMT_No_Available_Lines
      : this.labels.DMT_No_Available_Opportunities;
  }
  resetTableScroll() {
  const scroller = this.template.querySelector('.containerWithData');
  if (!scroller) return;

  // 1) inmediato
  scroller.scrollTop = 0;
  scroller.scrollLeft = 0;

}
}