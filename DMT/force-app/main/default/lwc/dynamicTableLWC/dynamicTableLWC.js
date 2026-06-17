import { LightningElement, api,track, wire  } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { loadScript } from 'lightning/platformResourceLoader';
import { FlexCardMixin  } from 'omnistudio/flexCardMixin';
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

    info = [];
    labels = {
    DMT_No_Records,DMT_No_Available_Opportunities,DMT_No_Available_Lines
};
    colString;
    maxRowSelection;
    initialRecords;
    @api searchBar = false;
    hideCheckbox;
    catalog;
    @api defaultselectedRows;
    showTable = true;
    @api showEditTable = false;
    recalculateTableValue = false;
    columnChanged;
    dataChanged;
    draftValuesTable;
    @api customTypeTable = false;
    teamMembers;
    userProfileName;
    userDMTRoles;
    userId = Id;
    tableRendered = false;
    linesParents;
    @track isLoading = false;



    colStringTemp;
    tableKey = Date.now(); 
    newSelectedClientId;
    oldSelectedClientId;
    columnWidthsMode = "auto";
    newTabChange;
    oldTabChange;
    _canvas;
    _ctx;
    normalizedColumns = false;
    labelNoRecordTable;


    @wire(getRecord, { recordId: Id, fields: [ProfileName, DMT_User_Role__c] })
    userDetails({ error, data }) {
        if (data) {
            if (data.fields.Profile.value != null) {
                this.userProfileName = data.fields.Profile.value.fields.Name.value;
                this.userDMTRoles = data.fields.DMT_User_Role__c.value;
                if (this.userProfileName != undefined && this.userProfileName != null && this.info != null && this.info != undefined && this.info.length > 0 && this.teamMembers != null && this.teamMembers != undefined  && this.linesParents != null && this.linesParents != undefined) {
                  this.handleUrlActivation();
                }
            }
        }
    }
  

    @api
    get  showTableName() {
      return this.showTable;
    }
  
    set showTableName(value) {
      this.showTable = (value.toLowerCase() === 'true');
    }

    @api
    get  recalculateTable() {
      return this.recalculateTableValue;
    }
  
    set recalculateTable(value) {
      if(value.toLowerCase() === 'true'){
        this.recalculateMethod(this.columnChanged,this.dataChanged);
        this.recalculateTableValue = false;
      }
      
    }
    
    @api
    get  catalogName() {
      return this.catalog;
    }
  
    set catalogName(value) {
      this.catalog = value;
    }

    
    @api
    get  labelNorecords() {
      return this.labelNoRecordTable;
    }
  
    set labelNorecords(value) {
      this.labelNoRecordTable = value;
    }
    @api
    get  hideCheckboxName() {
      return this.hideCheckbox;
    }
  
    set hideCheckboxName(value) {
      this.hideCheckbox = (value.toLowerCase() === 'true');
    }
    @api
    get  selectedClient() {
      return this.newSelectedClientId;
    }
  
    set selectedClient(value) {

      this.newSelectedClientId = value;   
      
    }

    @api
    get changeTab() {
        return this.newTabChange;
    }
    set changeTab(value) {
    this.newTabChange = value;
    if (this.oldTabChange != this.newTabChange) {
        this.oldTabChange =  this.newTabChange;
        this.enableAutoMode();
    }
    }
    
    @api
    get  infoName() {
      return this.info;
    }
  
    set infoName(value) {
      this.isLoading = true;
      this.info = Array.isArray(value) && value.length > 0 && (value[0]?.NameURLLine !== NO_RECORDS_FLAG && value[0]?.NameURL !== NO_RECORDS_FLAG) ? value: [];
      if(((!this.normalizedColumns) || (this.newSelectedClientId != this.oldSelectedClientId))){
          this.enableAutoMode();
          this.normalizedColumns = true;
          this.oldSelectedClientId = this.newSelectedClientId;
      }
      this.initialRecords = this.info;
      if (this.userProfileName != undefined && this.userProfileName != null && this.info != null && this.info != undefined && this.info.length > 0 && this.teamMembers != null && this.teamMembers != undefined && this.linesParents != null && this.linesParents != undefined) {
        this.handleUrlActivation();
      }
      this.isLoading = false;
    }

    @api
    get colName() {
        return this.colString;
      }
    
      set colName(value) {
        if(value === 'derivativesRiskLimit'){
          this.colString = [      {       "label": "Total Limit",       "fieldName": "Total_Limit_Treasury_Risk__c",        "editable":"true",          "hideDefaultActions":"true",        "columnChanged":"false"     }, {       "label": "0-1",       "fieldName": "First_Term_Treasury_Risk__c",        "editable":"true",           "hideDefaultActions":"true",        "columnChanged":"false"     },     {       "label": "1-2",       "fieldName": "Second_Term_Treasury_Risk__c",        "editable":"true",            "hideDefaultActions":"true",        "columnChanged":"false"     },     {       "label": "2-3",       "fieldName": "Third_Term_Treasury_Risk__c",        "editable":"true",           "hideDefaultActions":"true",        "columnChanged":"false"     },     {       "label": "3-5",       "fieldName": "Fourth_Term_Treasury_Risk__c",        "editable":"true",          "hideDefaultActions":"true",        "columnChanged":"false"     },     {       "label": "5-8",       "fieldName": "Fifth_Term_Treasury_Risk__c",        "editable":"true",      "hideDefaultActions":"true",        "columnChanged":"false"     },     {       "label": "8-10",       "fieldName": "Sixth_Term_Treasury_Risk__c",        "editable":"true",        "hideDefaultActions":"true",        "columnChanged":"false"     },     {       "label": "10-12",       "fieldName": "Seventh_Term_Treasury_Risk__c",        "editable":"true",      "hideDefaultActions":"true",        "columnChanged":"false"     },     {       "label": ">12",       "fieldName": "Eighth_Term_Treasury_Risk__c",        "editable":"true",     "hideDefaultActions":"true",        "columnChanged":"false"     }   ];
        }else{
        this.colString = value;
        this.colStringTemp = value;
        this.normalizedColumns = false;

        if(this.info.length > 0 ){
          this.enableAutoMode();
          this.normalizedColumns = true;
        }
        }
      }

      @api
      get  maxRowName() {
        return this.maxRowSelection;
      }
    
      set maxRowName(value) {
        this.maxRowSelection = value;
      }

      @api
      get teamMember() {
        return this.teamMembers;
      }
    
      set teamMember(value) {
        this.teamMembers = value;
        if (this.userProfileName != undefined && this.userProfileName != null && this.info != null && this.info != undefined && this.info.length > 0 && this.teamMembers != null && this.teamMembers != undefined && this.teamMembers.length > 0) {
          this.handleUrlActivation();
        }
      }

      @api
      get lineParents() {
        return this.linesParents;
      }
    
      set lineParents(value) {
        this.linesParents = value;
        if (this.userProfileName != undefined && this.userProfileName != null && this.info != null && this.info != undefined && this.info.length > 0 && this.teamMembers != null && this.teamMembers != undefined && this.linesParents != null && this.linesParents != undefined) {
          this.handleUrlActivation();
        }
      }

    connectedCallback(){
        loadStyle(this, datatablestyles);
    }

    isJsonString(str) {
        try {
            JSON.parse(str);
        } catch (e) {
            return false;
        }
        return true;
    }

    handleUrlActivation() {
      let infoAux = JSON.parse(JSON.stringify(this.info));
      const lineIdsSet = new Set();
      for (var i=0; i<infoAux.length; i++) {
        lineIdsSet.add(infoAux[i].Id);
      }
      for (var i=0; i<infoAux.length; i++) {
        let foundMemb = null;
        if (this.teamMembers && this.teamMembers != "" && !(typeof this.teamMembers === 'string' || this.teamMembers instanceof String)){
          foundMemb = this.teamMembers.find((element) => element.LineId == infoAux[i].Id);
        }
        let foundMembParent = null;
        if (this.linesParents && this.linesParents != "" && !(typeof this.linesParents === 'string' || this.linesParents instanceof String)){
          foundMembParent = this.linesParents.find((element) => element.DMT_Parent_Line__c == infoAux[i].Id);
        }
        if ((!foundMemb && infoAux[i].OwnerId != this.userId) && !(infoAux[i].DMT_Origin__c == 'AMIWEB' && infoAux[i].Product__c == 'Risk Approval') && !this.userDMTRoles?.includes('DMT_Soporte funcional') && !this.userDMTRoles?.includes('Configurador SF')) {
          infoAux[i].isDisabled = true;
          infoAux[i].button = true;
          infoAux[i].buttonClass = 'buttonDisabled';
        } else if (infoAux[i].NameURLLine == '//NO RECORDS') {
          infoAux[i].Name = '//NO RECORDS';
          infoAux[i].isDisabled = true;
          infoAux[i].button = true;
          infoAux[i].buttonClass = 'buttonDisabled';
        } else if (infoAux[i].Status__c != 'Closed' || (infoAux[i].Product__c == 'Treasury Line' && foundMembParent) || infoAux[i].DMT_Cancel__c|| (infoAux[i].Product__c == 'Line' && foundMembParent)) {
          infoAux[i].button = true;
        }
      }
      this.info = JSON.parse(JSON.stringify(infoAux));
    }
    
    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows;
        this.dispatchEvent(new CustomEvent('rowselected',  { bubbles:true, composed:true,detail: {rowSelect : this.selectedRows, catalog : this.catalog}} ));
  
    }
    // Search Event

    handleRowAction(event) {
      const action = event.detail.action;
      if (action.actionName == 'goToRecord') {
        const row = event.detail.row;
        this[NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: {
                recordId: row.Id,
                objectApiName: 'DMT_Line__c',
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, "_blank");
        });      
      } else {
        const row = event.detail.row;
        this.dispatchEvent(new CustomEvent('renewline',  { bubbles:true, composed:true,detail:row.Id}));
      }
    }

    handleSearch(event) {
        this.isLoading = true;
        const searchKey = event.target.value.toLowerCase();
        if (searchKey) {

            this.data = this.initialRecords;

            if (this.data) {

                let searchRecords = [];

                for (let record of this.data) {
                    let valuesArray = Object.values(record);

                    for (let val of valuesArray) {

                        
                        let strVal = String(val);

                        if (strVal) {

                            if (strVal.toLowerCase().includes(searchKey)) {

                                searchRecords.push(record);
                                break;
                            }
                        }
                    }
                }
                this.info = searchRecords;
            }
        } else {
          this.info =this.initialRecords;
        }
      this.isLoading = false;
    }

     saveHandleAction(event) {
       this.isLoading = true;
       const draftValues = event.detail.draftValues;
       const changedColumns = [];
       const newValues = [];
       draftValues.forEach(draft => {
           const fieldName = Object.keys(draft)[1]; // Obtiene el nombre de la columna cambiada
           const newValue = draft[fieldName]; // Obtiene el nuevo valor
           changedColumns.push(fieldName);
           newValues.push(newValue);
       });
       if(changedColumns[0] === 'Total_Limit_Treasury_Risk__c'){
        this.columnChanged = changedColumns[0] ;
        this.dataChanged = newValues;
       }
        var dataInfo = this.copiarLista(this.info);
        var dataColumn = this.copiarLista(this.colString);
        dataInfo[0][changedColumns[0]] = newValues[0];
        this.dispatchEvent(new CustomEvent('tableChanges',  { bubbles:true, composed:true,detail:  dataInfo[0]} ));
      this.draftValuesTable = null;
      this.isLoading = false;
}

calculateLimits(changedColumns, newValues){
  var dataInfo = this.copiarLista(this.info);
  var dataColumn = this.copiarLista(this.colString);
  dataColumn.forEach(column => {
    if (column.fieldName === changedColumns[0]) { 
      column.columnChanged = "true";
    }
});
  dataInfo[0][changedColumns[0]] = newValues[0];
  
  if(dataColumn[0]["columnChanged"] !== "true"){
    dataInfo[0]["totalLimit"] = Math.max(Number(dataInfo[0]["firstTerm"])+Number(dataInfo[0]["secondTerm"])+Number(dataInfo[0]["thirdTerm"]),Number(dataInfo[0]["fourthTerm"])*0.75,Number(dataInfo[0]["fifthTerm"])*0.5,Number(dataInfo[0]["sixthTerm"])*0.3,(Number(dataInfo[0]["seventhTerm"]) +Number(dataInfo[0]["eighthTerm"]))*0.2);
  }
  
  if(dataColumn[1]["columnChanged"] !== "true"){
    if(dataColumn[2]["columnChanged"] !== "true"){
      
      if(dataColumn[3]["columnChanged"] !== "true"){
        dataInfo[0]["thirdTerm"] = Number(dataInfo[0]["totalLimit"])/3;
        dataInfo[0]["secondTerm"] = Number(dataInfo[0]["totalLimit"])/3;
        dataInfo[0]["firstTerm"] = Number(dataInfo[0]["totalLimit"])/3;
      }
      else{
        dataInfo[0]["secondTerm"] = Math.max(0,(Number(dataInfo[0]["totalLimit"]) - Number(dataInfo[0]["thirdTerm"]))/2);
        dataInfo[0]["firstTerm"] = Math.max(0,(Number(dataInfo[0]["totalLimit"]) - Number(dataInfo[0]["thirdTerm"]))/2);
      }
    }
    else{
      if(dataColumn[3]["columnChanged"] !== "true"){
        dataInfo[0]["thirdTerm"] = Math.max(0,(Number(dataInfo[0]["totalLimit"]) - Number(dataInfo[0]["secondTerm"]))/2);
        dataInfo[0]["firstTerm"] = Math.max(0,(Number(dataInfo[0]["totalLimit"]) - Number(dataInfo[0]["secondTerm"]))/2);
      }
      else{
        dataInfo[0]["firstTerm"] = Math.max(0,Number(dataInfo[0]["totalLimit"]) - Number(dataInfo[0]["secondTerm"]) - Number(dataInfo[0]["thirdTerm"]));
      }
    }

  }else{
    if(dataColumn[2]["columnChanged"] !== "true"){
      
      if(dataColumn[3]["columnChanged"] !== "true"){
        dataInfo[0]["thirdTerm"] = Math.max(0,(Number(dataInfo[0]["totalLimit"]) - Number(dataInfo[0]["firstTerm"]))/2);
        dataInfo[0]["secondTerm"] = Math.max(0,(Number(dataInfo[0]["totalLimit"]) - Number(dataInfo[0]["firstTerm"]))/2);
      }
      else{
        dataInfo[0]["thirdTerm"] = Math.max(0,(Number(dataInfo[0]["totalLimit"]) - Number(dataInfo[0]["firstTerm"]) - Number(dataInfo[0]["secondTerm"])));
      }
      
    }
    else{
      if(dataColumn[3]["columnChanged"] !== "true"){
        dataInfo[0]["thirdTerm"] = Math.max(0,(Number(dataInfo[0]["totalLimit"]) - Number(dataInfo[0]["secondTerm"]) - Number(dataInfo[0]["firstTerm"])));
      }else{
        console.log('tres primeros rellenos');
      }
    }
  }
  
  
  if(dataColumn[4]["columnChanged"] !== "true"){
    dataInfo[0]["fourthTerm"] = Number(dataInfo[0]["totalLimit"])*0.75;
  }
  if(dataColumn[5]["columnChanged"] !== "true"){
    dataInfo[0]["fifthTerm"] = Number(dataInfo[0]["totalLimit"])*0.5;
  }
  if(dataColumn[6]["columnChanged"] !== "true"){
    dataInfo[0]["sixthTerm"] = Number(dataInfo[0]["totalLimit"])*0.3;
  }
  if(dataColumn[7]["columnChanged"] !== "true" ){
    if(dataColumn[8]["columnChanged"] !== "true" ){
      dataInfo[0]["seventhTerm"] = Number(dataInfo[0]["totalLimit"])*0.1;
      dataInfo[0]["eighthTerm"] = Number(dataInfo[0]["totalLimit"])*0.1;
    }
    else{
      dataInfo[0]["seventhTerm"] = Math.max(0,Number(dataInfo[0]["totalLimit"])*0.2 - Number(dataInfo[0]["eighthTerm"]));
    } 
  }
  else{
    if(dataColumn[8]["columnChanged"] !== "true" ){
      dataInfo[0]["eighthTerm"] = Math.max(0,Number(dataInfo[0]["totalLimit"])*0.2 - Number(dataInfo[0]["seventhTerm"]));
    }

  }
  return {dataColumn,dataInfo};
}

copiarLista(listaOriginal) {
  return listaOriginal.map(elemento => {
    if (typeof elemento === 'object' && elemento !== null) {
      return JSON.parse(JSON.stringify(elemento));
    } else {
      return elemento; // Devolver una copia directa para valores primitivos
    }
  });
}

recalculateMethod(columnChanged, dataChanged){
  this.isLoading = true;
  var dataInfo = this.copiarLista(this.info);
  var dataColumn = this.copiarLista(this.colString);

  dataInfo[0][columnChanged] = dataChanged[0];
  
  dataInfo[0]["Third_Term_Treasury_Risk__c"] = Math.floor(Number(dataInfo[0]["Total_Limit_Treasury_Risk__c"]));
  dataInfo[0]["Second_Term_Treasury_Risk__c"] = Math.floor(Number(dataInfo[0]["Total_Limit_Treasury_Risk__c"]));
  dataInfo[0]["First_Term_Treasury_Risk__c"] = Math.floor(Number(dataInfo[0]["Total_Limit_Treasury_Risk__c"]));
  dataInfo[0]["Fourth_Term_Treasury_Risk__c"] = Math.floor(Number(dataInfo[0]["Total_Limit_Treasury_Risk__c"])*0.75);
  dataInfo[0]["Fifth_Term_Treasury_Risk__c"] = Math.floor(Number(dataInfo[0]["Total_Limit_Treasury_Risk__c"])*0.5);
  dataInfo[0]["Sixth_Term_Treasury_Risk__c"] = Math.floor(Number(dataInfo[0]["Total_Limit_Treasury_Risk__c"])*0.3);
  dataInfo[0]["Seventh_Term_Treasury_Risk__c"] = Math.floor(Number(dataInfo[0]["Total_Limit_Treasury_Risk__c"])*0.2);
  dataInfo[0]["Eighth_Term_Treasury_Risk__c"] = Math.floor(Number(dataInfo[0]["Total_Limit_Treasury_Risk__c"])*0.2);

  this.dispatchEvent(new CustomEvent('tableChanges',  { bubbles:true, composed:true,detail:  dataInfo[0]} ));
  this.isLoading = false;
}

handleScroll (event) {
  this.scroll = event.target.scrollTop;
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
    const monthMap = { jan:0,feb:1,mar:2,apr:3,may:4,jun:5,jul:6,aug:7,sep:8,oct:9,nov:10,dec:11 };
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

      // If it is sorted by Start Date or End Date, parse 'DD-MMM-YYYY' to UTC number
      if (fieldname === FIELD_START_DATE || fieldname === FIELD_END_DATE) {
        x = x ? this.parseDdMonYyyy(x) : null;
        y = y ? this.parseDdMonYyyy(y) : null;
      }

      // Nulls at the end in asc and at the beginning in desc
      if (x == null && y == null) return 0;
      if (x == null) return 1 * isReverse;
      if (y == null) return -1 * isReverse;

      if (x > y) return 1 * isReverse;
      if (x < y) return -1 * isReverse;
      return 0;
    });

    this.info = parseData;
}

get _fewCols() {
  return Array.isArray(this.colString) && this.colString.length > 0 && this.colString.length <= 7;
}

get containerStyle() {
  const base = 'margin-top:1.0vh;overflow:auto;max-width:100%;  width:100%;';
  return base;
  //return this._fewCols ? `${base} width:100%;min-height: 40vh;` : `${base} width:fit-content;`;
}

get dataTableStyle() {
  //return this._fewCols ? `${base} display:block; width:100%; min-width:100%;` : `${base} display:inline-block;`;
  //return 'height:auto; display:block; width:100%; min-width:100%;';
  const colCount = Array.isArray(this.colString) ? this.colString.length : 0;
  //If a double scroll bar appears, modify the 9.67 which is the column min width
  const min = colCount > 0 ? colCount * 9.67 : 89; // 200px por columna aprox
  return `height:auto;display:block;width:100%;min-width:${min}rem;`;
}

get containerWithData(){
  
  return this.info.length > 0 ? "containerWithData" : "dynamicTable containerWithOutData";
}
get tableWithData(){
  return this.info.length > 0 ? "tableWithData" : "tableWithOutData ";
}

get isEmptyTable(){
  return this.info.length > 0 ? false : true;
}

get textoNoAvailableRecords() {
  return this.newTabChange === "Lines"
    ? this.labels.DMT_No_Available_Lines
    : this.labels.DMT_No_Available_Opportunities;
}
textWidthPx(text) {
    const str = (text ?? '').toString();
    if (!this._canvas) {
        this._canvas = document.createElement('canvas');
        this._ctx = this._canvas.getContext('2d');
        this._ctx.font = '14px "Salesforce Sans", Arial, sans-serif';
    }
    const metrics = this._ctx.measureText(str);
    const textWidth = metrics.width;
    const cellPadding = 48;
    return Math.ceil(textWidth + cellPadding);
}

async enableAutoMode() {
    // 1) Compute column widths using FIXED mode with initialWidth
    await this.applyWidthsByContent();

    // 2) Wait for the DOM to render with the new widths
    await this.nextFrame();

    // 3) Restore original column definitions and switch back to AUTO mode
    this.colString = this.colStringTemp;
    this.columnWidthsMode = "auto";
}

// Main logic: compute widths based on content and fill remaining space
async applyWidthsByContent() {
    const maxColumnWidth = 650;
    const minColumnWidth = 90;
    const rows = Array.isArray(this.info) ? this.info : [];

    // 1) Compute base width per column based on longest text (label or cell value)
    let newCols = (this.colString || []).map(col => {
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
        const px = this.textWidthPx(longestValue);
        c.initialWidth = Math.max(minColumnWidth, Math.min(px, maxColumnWidth));
        return c;
    });

    this.colString = newCols;
    this.columnWidthsMode = 'fixed';
    this.tableKey = Date.now();
    await this.nextFrame();
}

nextFrame() {
    // Resolves on the next browser rendering frame
    return new Promise(resolve => requestAnimationFrame(resolve));
}

}