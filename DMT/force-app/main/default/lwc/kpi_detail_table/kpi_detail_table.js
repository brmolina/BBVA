import { api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningModal from 'lightning/modal';
import {refreshApex} from '@salesforce/apex';
import LightningConfirm from "lightning/confirm";
import getObligation from '@salesforce/apex/KPI_DetailTableController.getObligation';
import refreshObligation from '@salesforce/apex/KPI_DetailTableController.refreshObligation';
import putObligation from '@salesforce/apex/KPI_DetailTableController.putObligation';
import postObligation from '@salesforce/apex/KPI_DetailTableController.postObligation';
import getCatalog from '@salesforce/apex/KPI_DetailTableController.getCatalog';
import deteleObligation from '@salesforce/apex/KPI_DetailTableController.deleteObligation';
import KPI_NoData from '@salesforce/label/c.KPI_NoData';
import kpi_firstColumInfo from '@salesforce/label/c.KPI_FirstColumn';
const kpiComplianceOptions = [{label :'Yes' , value:'Y'},{label :'No' , value:'N'},{label :' ' , value:'vacio'}];
const kpiReceptionStatusOptions = [{label :'Received' , value:'Received'},{label :'Pending' , value:'Pending'},{label: 'Claimed' , value: 'Claimed'},{label :'' , value:'vacio'}];
const columns = [
    {label: "KPI Number", fieldName: 'kpiNumber',sortable: true, type: 'number',fixedWidth:70, cellAttributes: {alignment: 'left' },editable: { fieldName: 'editable2' }},
    {label: 'KPI Catalogue', fieldName: 'catalogue',sortable: true, type: 'picklistColumn',fixedWidth:190, cellAttributes: {alignment: 'left' }, editable: { fieldName: 'editable2' }, typeAttributes: 
    {
        options: { fieldName: 'catalogueOptions' },
        value: { fieldName: 'catalogue' },
        optionlabel: {fieldName: 'catalogLabel' }
      }
    },  
    {label: "KPI Description", fieldName: 'kpiDescription',sortable: true, type: 'kpiDescriptionCellType',fixedWidth:300, editable: { fieldName: 'editable2' }, cellAttributes: {alignment: 'left'}},
    {label: "Price Impact", fieldName: 'priceImpact',sortable: true, type: 'bpsColumn',fixedWidth:105, editable: { fieldName: 'editable2' }, cellAttributes: {alignment: 'left' }},
    {label: "Baseline Target" , fieldName: 'target',sortable: true, type: 'number',fixedWidth:75, editable: { fieldName: 'editable2' }, cellAttributes: {alignment: 'left' }},
    {label: "Baseline Year" , fieldName: 'baselineYear',sortable: true, type: 'textColumn',fixedWidth:75, editable: { fieldName: 'editable2' }, cellAttributes: {alignment: 'left' }},
    {label: "Effective Start Date (dd/mm/yyyy)", fieldName: 'effStartDate',sortable: true, type: 'date-local', fixedWidth:112, cellAttributes: {alignment: 'left' }, editable: { fieldName: 'editable2' },typeAttributes: {
      year: "numeric",
      month: "2-digit",
      day: "2-digit"
  }},
    {label: "Effective End Date (dd/mm/yyyy)", fieldName: 'effEndDate',sortable: true, type: 'date-local', fixedWidth:112, editable: { fieldName: 'editable2' }, cellAttributes: {alignment: 'left' },typeAttributes: {
      year: "numeric",
      month: "2-digit",
      day: "2-digit"
  }},
    {label: "Deadline Reception KPI (dd/mm/yyyy)", fieldName: 'alertObligationDate',sortable: true, type: 'date-local', fixedWidth:112, editable: { fieldName: 'editable2' },  cellAttributes: {alignment: 'left'  ,minimumFractionDigits :'6'},typeAttributes: {
      year: "numeric",
      month: "2-digit",
      day: "2-digit"
  }},
    {label: "Minimum Criteria", fieldName: 'minCriteria',sortable: true, type: 'picklistColumn',fixedWidth:186, cellAttributes: {alignment: 'left' }, editable: { fieldName: 'editable2' }, typeAttributes: 
    {
        options: { fieldName: 'criteriaOptions' },
        value: { fieldName: 'minCriteria' },
        optionlabel: {fieldName: 'minCriteriaLabel' }}
    },
    {label: "Minimum Value", fieldName: 'minValue',sortable: true, type: 'minValueColumn',fixedWidth:100, editable: { fieldName: 'editable2' },  cellAttributes: {alignment: 'left'  ,minimumFractionDigits :'6'}},
    {label: "Maximum Criteria", fieldName: 'maxCriteria',sortable: true, type: 'picklistColumn',fixedWidth:186, cellAttributes: {alignment: 'left' },editable: { fieldName: 'editable2' } , typeAttributes: 
      {
        options: { fieldName: 'criteriaOptions' },
        value: { fieldName: 'maxCriteria' },
        optionlabel: {fieldName: 'maxCriteriaLabel' }
      }
    },
    {label: "Maximum Value", fieldName: 'maxValue',sortable: true, type: 'minValueColumn',fixedWidth:100, editable: { fieldName: 'editable2' },  cellAttributes: {alignment: 'left' ,minimumFractionDigits :'6'}},
    {label: "Actual Value", fieldName: 'alertsCovenantAmount',sortable: true, type: 'number',fixedWidth:100, editable: { fieldName: 'editable2' },  cellAttributes: {alignment: 'left'  }},
    {label: "Reception Status", fieldName: 'statusObligationDesc',sortable: true, type: 'picklistColumn',fixedWidth:105,cellAttributes: {alignment: 'left'}, editable: { fieldName: 'editable2' },  typeAttributes: {
      options: { fieldName: 'statusObligationDescOptions' },
      value: { fieldName: 'statusObligationDesc' },
      optionlabel: {fieldName: 'statusObligationDescLabel' }}
  },
    {label: "Reception Date (dd/mm/yyyy)", fieldName: 'receptDate',sortable: true, type: 'date-local', fixedWidth:112, editable: { fieldName: 'editable2' },  cellAttributes: {alignment: 'left'},typeAttributes: {
      year: "numeric",
      month: "2-digit",
      day: "2-digit"
  }},
    {label: "Trigger Compliant", fieldName: 'triggerCompliant',sortable: true, type: 'picklistColumn',fixedWidth:71,cellAttributes: {alignment: 'left'}, editable: { fieldName: 'editable2' },  typeAttributes: {
      options: { fieldName: 'triggerComplianceOptions' },
      value: { fieldName: 'triggerCompliant' },
      optionlabel: {fieldName: 'triggerComplianceLabel' }}
  },
    {type: 'action', typeAttributes: {rowActions: [{label: 'New KPI', name: 'new_trigger'}, {label: 'Delete KPI', name: 'delete'}]}}
];
const columns2 = [
  {label: "KPI Number", fieldName: 'kpiNumber',sortable: true, type: 'number',fixedWidth:70, cellAttributes: {alignment: 'left'}},
  {label: "KPI Number", fieldName: 'kpiNumber',sortable: true, type: 'number',fixedWidth:70, cellAttributes: {alignment: 'left'}},
  {label: 'KPI Catalogue', fieldName: 'catalogue',sortable: true, type: 'picklistColumn',fixedWidth:190, cellAttributes: {alignment: 'left'}, typeAttributes: {
      options: { fieldName: 'catalogueOptions' },
      value: { fieldName: 'catalogue' },
      optionlabel: {fieldName: 'catalogLabel' }}
  },
  {label: "KPI Description", fieldName: 'kpiDescription',sortable: true, type: 'kpiDescriptionCellType',fixedWidth:300, cellAttributes: {alignment: 'left'}},
  {label: "Price Impact", fieldName: 'priceImpact',sortable: true, type: 'bpsColumn',fixedWidth:105, cellAttributes: {alignment: 'left'}},
  {label: "Baseline Target" , fieldName: 'target',sortable: true, type: 'number',fixedWidth:75, cellAttributes: {alignment: 'left'}}, 
  {label: "Baseline Year" , fieldName: 'baselineYear',sortable: true, type: 'textColumn',fixedWidth:75, cellAttributes: {alignment: 'left'}}, 
  {label: "Effective Start Date (dd/mm/yyyy)", fieldName: 'effStartDate', sortable: true, type: 'date-local', fixedWidth:112, cellAttributes: {alignment: 'left'}}, 
  {label: "Effective End Date (dd/mm/yyyy)", fieldName: 'effEndDate', sortable: true, type: 'date-local', fixedWidth:112, typeAttributes: {year: 'numeric', month: '2-digit', day: '2-digit'}, cellAttributes: {alignment: 'left'}}, 
  {label: "Deadline Reception KPI", fieldName: 'alertObligationDate', sortable: true, type: 'date-local', fixedWidth:112, typeAttributes: {year: 'numeric', month: '2-digit', day: '2-digit'},  cellAttributes: {alignment: 'left'  ,minimumFractionDigits :'6'}}, 
  {label: "Minimum Criteria", fieldName: 'minCriteria',sortable: true, type: 'picklistColumn',fixedWidth:186, typeAttributes: { 
      options: { fieldName: 'criteriaOptions' }, 
      value: { fieldName: 'minCriteria' }} 
  }, 
  {label: "Minimum Value", fieldName: 'minValue',sortable: true, type: 'minValueColumn',fixedWidth:100, cellAttributes: {alignment: 'left' ,minimumFractionDigits :'6'}}, 
  {label: "Maximum Criteria", fieldName: 'maxCriteria',sortable: true, type: 'picklistColumn',fixedWidth:186, cellAttributes: {alignment: 'left'}, typeAttributes: { 
      options: { fieldName: 'criteriaOptions' }, 
      value: { fieldName: 'maxCriteria' }, 
      optionlabel: {fieldName: 'maxCriteriaLabel' } 
    } 
  }, 
  {label: "Maximum Value", fieldName: 'maxValue',sortable: true, type: 'minValueColumn',fixedWidth:100, cellAttributes: {alignment: 'left' ,minimumFractionDigits :'6'}}, 
  {label: "Actual Value", fieldName: 'alertsCovenantAmount',sortable: true, type: 'number',fixedWidth:100,  cellAttributes: {alignment: 'right'  }}, 
  //{label: "Obligation Date", fieldName: 'obligationDate', type: 'date-local', fixedWidth:112, typeAttributes: {year: 'numeric', month: '2-digit', day: '2-digit'}, cellAttributes: {alignment: 'left'  ,minimumFractionDigits :'6'}},
  {label: "Reception Status", fieldName: 'statusObligationDesc',sortable: true, type: 'picklistColumn',fixedWidth:105, cellAttributes: {alignment: 'left'}, typeAttributes: {
    options: { fieldName: 'statusObligationDescOptions' },
    value: { fieldName: 'statusObligationDesc' }, 
    optionlabel : { fieldName: 'statusObligationDescLabel' }
  }},
  {label: "Reception Date (dd/mm/yyyy)", fieldName: 'receptDate',sortable: true, type: 'date-local', fixedWidth:112, typeAttributes: {year: 'numeric', month: '2-digit', day: '2-digit'},  cellAttributes: {alignment: 'left'}},
  {label: "Trigger Compliant", fieldName: 'triggerCompliant',sortable: true, type: 'picklistColumn', fixedWidth:71, cellAttributes: {alignment: 'left'}, typeAttributes: 
    {
      options: { fieldName: 'triggerComplianceOptions' },
      value: { fieldName: 'triggerCompliant' },
      optionlabel: {fieldName: 'triggerComplianceLabel' }
    }
  }
];

export default class Kpi_detail_table extends LightningModal {

  
  draftValues = [];
  disableSave = true;
  sortOrder = ['null'];
  labelFirstColum = kpi_firstColumInfo;
  labelData = KPI_NoData;
  baseLineYear;
  @track sortBy;
  @track sortedDirection;
  @track errors;
  @track showModal = true;
  @track isLoading = true;
  @track noData = false;
  @track comboBoxOptions = [];
  @track data = [];
  @track dinamicData = [];
  @track kpiCatalogueOptions;
  @track kpiCriteriaOptions;
  @api contract ;
  @api sameRowDetail ;

  columns= [];
 
  @api
  get saveDisabled() {
    return this.disableSave;
  }
  connectedCallback(){
    refreshApex(this.data);
    refreshApex(this.dinamicData);
  }
  @wire(getCatalog, {
    catalogId: 'KPI_TYPE',
  }) catalog( { error, data } ) {
    if (data) {
      let tempArray =[];
      tempArray.push(...data.options);
      tempArray.push({label :'' , value:'vacio'});
      this.kpiCatalogueOptions = tempArray;   
    } else if (error) {
        console.error(error);
    }
  };

  @wire(getCatalog, {
    catalogId: 'CRITERIA_NAME',
  }) criteria( { error, data } ) {
    if (data) {
      let tempArray =[];
      tempArray.push(...data.options);
      tempArray.push({label :'' , value:'vacio'});
      this.kpiCriteriaOptions = tempArray;
    } else if (error) {
        console.error(error);
    }
  };

  @wire(getObligation, {
     contract: '$contract.contractId',
     category: '$contract.sustainableSubCategoryId',
     catalogue: '$kpiCatalogueOptions',
     criteria: '$kpiCriteriaOptions',
     timeStamp : Date.now()
  }) obligations( { error, data } ) {
    if (data) {
        this.updateDataTable(data);
        this.recallService();
        this.isLoading = false;
    } else if (error) {
        this.error = error;
        console.log(JSON.stringify(error));
        this.isLoading = false;
    }

  };

  updateDataTable(data) {
    this.data = [];
    this.dinamicData = [];
    this.columns=this.contract.editable ? columns : columns2;
      if (data.success && data.data.length > 0) {
        var tableData = [];
        var yearOptions = [];
        data.data.forEach( data =>  {
          data.actions.forEach( action =>  {
            action.triggers.forEach( (trigger, index) =>  {
              if(Array.isArray(trigger.reviews) ){
                if(trigger.reviews.length > 0){
                  trigger.reviews.forEach( (review, index) =>  {
                      var rowData = {
                      catalogue: this.checkUndefined(data,['obligationType','id']),
                      catalogLabel: this.getOptionLabel(this.kpiCatalogueOptions, this.checkUndefined(data,['obligationType','id'])),
                      catalogueOptions : this.kpiCatalogueOptions,
                      maxCriteriaLabel: this.getOptionLabel(this.kpiCriteriaOptions, this.checkUndefined(trigger,['scale','criteriaIdMaximum'])),
                      minCriteriaLabel: this.getOptionLabel(this.kpiCriteriaOptions, this.checkUndefined(trigger,['scale','criteriaIdMinimum'])),
                      triggerId: this.checkUndefined(trigger,['id']),
                      kpiNumber: this.checkUndefined(trigger,['scale','sortOrder']),            
                      target: this.checkUndefined(data,['baselineTarget']),
                      priceImpact: this.checkUndefined(trigger,['scale','rate']),
                      effStartDate: this.checkUndefined(trigger,['scale','effectiveStartDate']),
                      effEndDate: this.checkUndefined(trigger,['scale','effectiveEndDate']),
                      minCriteria: this.checkUndefined(trigger,['scale','criteriaIdMinimum']),
                      minValue: this.checkUndefined(trigger,['scale','criteriaValueMinimum']),
                      maxCriteria: this.checkUndefined(trigger,['scale','criteriaIdMaximum']),
                      maxValue: this.checkUndefined(trigger,['scale','criteriaValueMaximum']),
                      obligationId: this.checkUndefined(data,['id']),
                      scaleId: this.checkUndefined(trigger,['scale','id']),
                      criteriaOptions: this.kpiCriteriaOptions,
                      editable:true,
                      editable2:this.contract.editable,
                      baselineYear : this.checkUndefined(data,['baselineYear']),
                      triggerCompliant : this.checkUndefined(data,['triggerCompliant']),
                      triggerComplianceOptions  :  kpiComplianceOptions,
                      alertObligationDate : this.checkUndefined(review,['alertObligationDate']),
                      alertsCovenantAmount : this.checkUndefined(review,['obligationReview','covenant','amount']),
                      obligationDate : this.checkUndefined(review,['obligationDate']),
                      statusObligationDesc : this.checkUndefined(review,['obligationReview','receptionStatusDescription']),
                      receptDate : this.checkUndefined(review,['receptionDate']),
                      kpiDescription :  this.checkUndefined(data,['extendedDescription']),
                      reviewId : this.checkUndefined(review,['id']),
                      alertId : this.checkUndefined(review , ['alertId']),
                      obligationReviewExpectedDate : this.checkUndefined(review,['obligationReview','date']),
                      statusObligationDescOptions : kpiReceptionStatusOptions,
                      actionId : this.checkUndefined(action,['id'])
                    };
                    if(rowData.alertObligationDate){
                      let obligationDateYear = new Date(rowData.alertObligationDate).getFullYear();
                      yearOptions[obligationDateYear] = {label : obligationDateYear , value : obligationDateYear};
                    }
                    if(!rowData.editable2){
                      if(!this.sortOrder.includes(rowData.kpiDescription)){
                        if(!rowData.kpiDescription){
                          rowData.kpiDescription === ' ';
                        }
                        this.sortOrder.push(rowData.kpiDescription);
                      }
                      rowData.kpiNumber = this.sortOrder.findIndex(element => element === rowData.kpiDescription);
                    }
                    var complianceLabel =  kpiComplianceOptions.find(({ value })  => value === rowData.triggerCompliant);
                    if(complianceLabel) rowData.triggerComplianceLabel = complianceLabel.label;

                    var statusObligationDescLabel =  kpiReceptionStatusOptions.find(({ value })  => value === rowData.statusObligationDesc);
                    if(statusObligationDescLabel) rowData.statusObligationDescLabel = statusObligationDescLabel.label;

                    tableData.push(rowData); 

                  });
                }else{
                  
                  var rowData = {
                    catalogue: this.checkUndefined(data,['obligationType','id']),
                    catalogLabel: this.getOptionLabel(this.kpiCatalogueOptions, this.checkUndefined(data,['obligationType','id'])),
                    catalogueOptions : this.kpiCatalogueOptions,
                    kpiDescription :  this.checkUndefined(data,['extendedDescription']),
                    maxCriteriaLabel: this.getOptionLabel(this.kpiCriteriaOptions, this.checkUndefined(trigger,['scale','criteriaIdMaximum'])),
                    minCriteriaLabel: this.getOptionLabel(this.kpiCriteriaOptions, this.checkUndefined(trigger,['scale','criteriaIdMinimum'])),
                    triggerId: this.checkUndefined(trigger,['id']),
                    kpiNumber: this.checkUndefined(trigger,['scale','sortOrder']),            
                    target: this.checkUndefined(data,['baselineTarget']),
                    priceImpact: this.checkUndefined(trigger,['scale','rate']),
                    effStartDate: this.checkUndefined(trigger,['scale','effectiveStartDate']),
                    effEndDate: this.checkUndefined(trigger,['scale','effectiveEndDate']),
                    minCriteria: this.checkUndefined(trigger,['scale','criteriaIdMinimum']),
                    minValue: this.checkUndefined(trigger,['scale','criteriaValueMinimum']),
                    maxCriteria: this.checkUndefined(trigger,['scale','criteriaIdMaximum']),
                    maxValue: this.checkUndefined(trigger,['scale','criteriaValueMaximum']),
                    obligationId: this.checkUndefined(data,['id']),
                    scaleId: this.checkUndefined(trigger,['scale','id']),
                    criteriaOptions: this.kpiCriteriaOptions,
                    editable:true,
                    editable2:this.contract.editable,
                    baselineYear : this.checkUndefined(data,['baselineYear']),
                    triggerCompliant : this.checkUndefined(data,['triggerCompliant']),
                    triggerComplianceOptions  :  kpiComplianceOptions,
                    statusObligationDescOptions : kpiReceptionStatusOptions   
                  };
                  if(!rowData.editable2){
                    if(!this.sortOrder.includes(rowData.kpiDescription)){
                      if(!rowData.kpiDescription){
                        rowData.kpiDescription === ' ';
                      }
                      this.sortOrder.push(rowData.kpiDescription);
                    }
                    rowData.kpiNumber = this.sortOrder.findIndex(element => element === rowData.kpiDescription);
                  }
                  tableData.push(rowData); 
                }
              }else{
                  var rowData = {
                    catalogue: this.checkUndefined(data,['obligationType','id']),
                    catalogueOptions : this.kpiCatalogueOptions,
                    catalogLabel: this.getOptionLabel(this.kpiCatalogueOptions, this.checkUndefined(data,['obligationType','id'])),
                    maxCriteriaLabel: this.getOptionLabel(this.kpiCriteriaOptions, this.checkUndefined(trigger,['scale','criteriaIdMaximum'])),
                    minCriteriaLabel: this.getOptionLabel(this.kpiCriteriaOptions, this.checkUndefined(trigger,['scale','criteriaIdMinimum'])),
                    triggerId: this.checkUndefined(trigger,['id']),
                    kpiNumber: this.checkUndefined(trigger,['scale','sortOrder']),            
                    target: this.checkUndefined(data,['baselineTarget']),
                    priceImpact: this.checkUndefined(trigger,['scale','rate']),
                    effStartDate: this.checkUndefined(trigger,['scale','effectiveStartDate']),
                    effEndDate: this.checkUndefined(trigger,['scale','effectiveEndDate']),
                    minCriteria: this.checkUndefined(trigger,['scale','criteriaIdMinimum']),
                    minValue: this.checkUndefined(trigger,['scale','criteriaValueMinimum']),
                    maxCriteria: this.checkUndefined(trigger,['scale','criteriaIdMaximum']),
                    maxValue: this.checkUndefined(trigger,['scale','criteriaValueMaximum']),
                    obligationId: this.checkUndefined(data,['id']),
                    scaleId: this.checkUndefined(trigger,['scale','id']),
                    criteriaOptions: this.kpiCriteriaOptions,
                    kpiDescription :  this.checkUndefined(data,['extendedDescription']),
                    editable:true,
                    editable2:this.contract.editable,
                    baselineYear : this.checkUndefined(data,['baselineYear']),
                    triggerCompliant : this.checkUndefined(data,['triggerCompliant']),
                    triggerComplianceOptions  :  kpiComplianceOptions,
                    statusObligationDescOptions : kpiReceptionStatusOptions   
                  }
                  if(!rowData.editable2){
                    if(!this.sortOrder.includes(rowData.kpiDescription)){
                      if(!rowData.kpiDescription){
                        rowData.kpiDescription === ' ';
                      }
                      this.sortOrder.push(rowData.kpiDescription);
                    }
                    rowData.kpiNumber = this.sortOrder.findIndex(element => element === rowData.kpiDescription);
                  }
                  tableData.push(rowData); 
                }
              // }          
            });
          });
        });
        this.comboBoxOptions = yearOptions.filter((year) => year.label);
        if(!this.contract.editable)tableData = tableData.sort((a, b) => a.kpiNumber - b.kpiNumber);
        refreshApex(this.data);
        refreshApex(this.dinamicData);
        this.data = tableData;
        this.data = this.data.slice();
        this.dinamicData = tableData;
        this.dinamicData = this.dinamicData.slice();
        this.isLoading = false;
    }else if(!Array.isArray(data.data)){
        this.noData = true;
        this.isLoading = false;
    } else {
      console.log(JSON.stringify(data));
      this.error = data.message;
      this.noData = true;
      console.error(data.message);
      this.isLoading = false;
    }
  }
  checkUndefined(data , params){
    try{
      var fieldsEmptyValue = ['minCriteria' ,'maxCriteria' , 'triggerCompliant' ,'statusObligationDesc'];
      var dynamicData = data;
      params.forEach(param => {
        if(fieldsEmptyValue.includes(param) && dynamicData[param] === 'vacio'){
          dynamicData = null;
          return;
        }else{
          dynamicData = dynamicData[param];
        }
      });
      return dynamicData ? dynamicData : undefined;
    }catch{
      return undefined;
    }
  }

  getOptionLabel(options, optionValue) {
    let found = options.find(( {value} ) => value === optionValue);
    if (found) {
        return found.label;
    }
  }

  addTrigger(event) {
    var newRow = {
        catalogue: null,
        kpiDescription: null,
        catalogueOptions: this.kpiCatalogueOptions,
        criteriaOptions: this.kpiCriteriaOptions,
        triggerComplianceOptions: kpiComplianceOptions,
        editable:true,
        editable2:this.contract.editable,
        newLineId : this.dinamicData.length,
        statusObligationDescOptions : kpiReceptionStatusOptions ,
        newRow : true
    };
    if(this.noData){
      this.noData=false;
    }
    //this.data.push(newRow);
    this.dinamicData = [...this.dinamicData, newRow];
    this.data = [...this.data, newRow];
  }

  async saveData() {
    // switches disabled state on buttons
    const saveStatus = await sendData(this.formData);
    return (saveStatus && saveStatus.success) ? closeModal() : mitigateSaveFailure();
  }

  async handleChange(event) {
    // set option label in selected KPI catalogue instead of value
    let cell = event.detail.draftValues[0];
    if ('catalogue' in cell) {
        this.dinamicData[cell.id.substring(4)].catalogLabel = this.getOptionLabel(this.kpiCatalogueOptions, cell.catalogue);
    }
    // set option label in selected KPI min criteria instead of value
    if ('minCriteria' in cell) {
        this.dinamicData[cell.id.substring(4)].minCriteriaLabel =cell.minCriteria === 'vacio'?  '' : this.getOptionLabel(this.kpiCriteriaOptions, cell.minCriteria);
    }

    // set option label in selected KPI min criteria instead of value
    if ('maxCriteria' in cell) {
      this.dinamicData[cell.id.substring(4)].maxCriteriaLabel = cell.maxCriteria === 'vacio'?  '' : this.getOptionLabel(this.kpiCriteriaOptions, cell.maxCriteria);
  }

    if ('triggerCompliant' in cell) {
      this.dinamicData[cell.id.substring(4)].triggerComplianceLabel = kpiComplianceOptions.find(({ value })  => value === cell.triggerCompliant).label;
    }

    if ('statusObligationDesc' in cell) {
      this.dinamicData[cell.id.substring(4)].statusObligationDescLabel = kpiReceptionStatusOptions.find(({ value })  => value === cell.statusObligationDesc).label;
      this.dinamicData[cell.id.substring(4)].statusObligationDesc = cell.statusObligationDesc;
    }

    this.disableSave = false;
  }

  async handleSaveClick(event) {
    this.disableSave = true;
    this.isLoading = true;
    const toUpdate = [];
    const toInsert = [];
    var notRunCall = false;
    var errorsToPush = {};
    this.template.querySelector('c-kpi_custom_datatable').draftValues.forEach(row => {
      //To compare the start date, i have to know if i had edited this parameters. If i edited them i asign it to a variable where i store the row.
      var constructedRow = this.dinamicData[row.id.substring(4)];
      constructedRow.effStartDate = row.effStartDate ? row.effStartDate : constructedRow.effStartDate;
      constructedRow.effEndDate = row.effEndDate ? row.effEndDate : constructedRow.effEndDate;
      //Now i compare the composed row fields to launch an datatable error
      if(constructedRow.effStartDate > constructedRow.effEndDate){
        var rowErrorMess = ['No es posible introducir una fecha de inicio mayor a la de fin'];
        var rowErrorField = ['effStartDate' ,'effEndDate'];
        errorsToPush[row.id] = {
          messages:rowErrorMess,
          fieldNames:rowErrorField,
          title:'Se ha encontrado un error'
        }
        notRunCall = true;
      
      }
      //if the description is not being edited nor exist in the actual data it cant be insert in the table. I launch an error to make it required 
      if(Object.keys(row).includes('kpiDescription') && !row.kpiDescription){
        var rowErrorMess = ['El campo description es obligatorio para calcular el KPI number'];
        var rowErrorField = ['kpiDescription'];
        errorsToPush[row.id] = {
          messages:rowErrorMess,
          fieldNames:rowErrorField,
          title:'Se ha encontrado un error'
        }
        notRunCall = true;
      }
    });
    if(notRunCall) {
      this.errors = {
        rows:errorsToPush
       }
      this.isLoading = false;
      return;
    }
    else{
      this.errors = undefined;
    }
    // get draft values: triggers to update and new triggers separated
    this.template.querySelector('c-kpi_custom_datatable').draftValues.slice().map((draftValue) => {
      if (this.dinamicData[draftValue.id.substring(4)].newRow) {
        toInsert.push(draftValue);
      } else {
        var lineElement = this.dinamicData[draftValue.id.substring(4)];

        Object.keys(draftValue).forEach(param => {
          if(param !=='id'){
            var column = columns.find(({ fieldName })  => fieldName === param);
            switch (column.type){
              case 'kpiDescriptionCellType':
              case 'textColumn':
                lineElement[param] = draftValue[param] ? draftValue[param] : '';
                break;
              case 'number':
              case 'minValueColumn':
                lineElement[param] = draftValue[param] ? draftValue[param] : 0.000000000000000000000000000001;
                break;
              case 'bpsColumn':
                lineElement[param] = draftValue[param] ? Number(draftValue[param]): 0.000000000000000000000000000001;
                break;
              case 'date-local':
              case 'dateColumn':
                lineElement[param] = draftValue[param] ? draftValue[param] : '0001-01-01';
                break;
              case 'picklistColumn':
                lineElement[param] = draftValue[param] === 'vacio' ? ''  : draftValue[param];
                break;
            }
          }
        });
          toUpdate.push(lineElement);
      }
    });
    const updateRequest = this.getUpdateRequest(toUpdate);
    const insertRequest = this.getInsertRequest(toInsert);

    // TODO validate fields
    // update
    try {
        putObligation({
          updateRequest: JSON.stringify(updateRequest)

        }).then(updateResult => {
          if(!updateResult.success)throw JSON.stringify(updateRequest);
            postObligation({
            insertRequest : JSON.stringify(insertRequest)

          }).then(insertResult => {
            if(!insertResult.success) throw insertResult.message;
            refreshObligation({
              contract: this.contract.contractId,
              category: this.contract.sustainableSubCategoryId,

            }).then(refreshedData => {
              // Clear all datatable draft values
              this.template.querySelector('c-kpi_custom_datatable').draftValues = [];
              this.updateDataTable(refreshedData);
              this.isLoading = false;

            }).catch(error => {
                //exception handling
                console.error(error);
                this.error = error;
                this.isLoading = false;
            });

          }).catch(error => {
            //exception handling
            //insert
            this.pushInsertError();
            console.error(error);
            this.error = error;
            this.isLoading = false;
        });

        }).catch(error => {
            //exception handling
            //edit error exception
            //coger de la draft los values que estamos actualizando los registros cuyo 
            this.pushUpdateError()
            console.log(JSON.stringify(error));
            console.error(error);
            this.error = error;
            this.isLoading = false;
        });

    } catch (error) {
        console.error('Error updating obligations', error.body.message);
    }
  }

  getUpdateRequest (toUpdate) {

    var updateRequest = null;

    if (toUpdate) {
      updateRequest = {obligations: []};
      //group values to update by catalogId
      const catalogIds = toUpdate.reduce((grouped, item) => {
        const group = (grouped[item.kpiDescription.toUpperCase()] || []);
        group.push(item);
        grouped[item.kpiDescription.toUpperCase()] = group;
        return grouped;
      }, {});
      //update request
      Object.keys(catalogIds).forEach(key => {
       
        catalogIds[key].forEach(line => {
          var catalogIdEntry = {
            id: line.obligationId,
            contract: { id: this.contract.contractId },
            sustainableSubcategory: { id: this.contract.sustainableSubCategoryId},
            // actions: [{ name: 'Margin Change', triggers: []  ,reviews: []}]
            actions: [{ name: 'Margin Change', triggers: [] ,id: line.actionId }]
          };
          var scale = {};
          scale['id'] = line.scaleId;
          scale['sortOrder'] = line.kpiNumber ;
          scale['criteriaIdMinimum'] =  line.minCriteria;
          scale['criteriaValueMinimum'] = line.minValue ;
          scale['criteriaIdMaximum'] =  line.maxCriteria;
          scale['criteriaValueMaximum'] = line.maxValue ;
          scale['effectiveStartDate'] = line.effStartDate ;
          scale['effectiveEndDate'] = line.effEndDate ;
          scale['rate'] = line.priceImpact ;
          var covenant = {
            amount : line.alertsCovenantAmount ,
          }
          var obligationReview = {
            receptionStatusDescription : line.statusObligationDesc,
            covenant : covenant
          }
          if(obligationReview.receptionStatusDescription ==='vacio')  obligationReview.receptionStatusDescription = '';
          var review = {
            receptionDate : line.receptDate ,
            alertObligationDate : line.alertObligationDate,
            obligationDate : line.obligationDate ,
            obligationReview: obligationReview,
            id : line.reviewId,
            alertId : line.alertId
          }
          var trigger = {
            id: line.triggerId,
            scale: scale,
            reviews: [review]
          };
          catalogIdEntry.actions[0].triggers.push(trigger);
          catalogIdEntry.obligationType= { id: line.catalogue };
          catalogIdEntry.baselineTarget = line.target;
          catalogIdEntry.baselineYear = line.baselineYear;
          catalogIdEntry.extendedDescription = line.kpiDescription ;
          catalogIdEntry.triggerCompliant = line.triggerCompliant ==='vacio'? ' ': line.triggerCompliant;
          updateRequest.obligations.push(catalogIdEntry);
        }); 
      });
    }
    return updateRequest;
  }

  getInsertRequest (toInsert) {

    var insertRequest = null;

    if (toInsert) {
       insertRequest = {obligations: []};
      // //group values to update by catalogId
      const catalogIds = toInsert.reduce((grouped, item) => {
        const group = (grouped[item.kpiDescription.toUpperCase()] || []);
        group.push(item);
        group.sort((a, b) => a.kpiNumber < b.kpiNumber);
        grouped[item.kpiDescription.toUpperCase()] = group;
        return grouped;
      }, {});
      Object.keys(catalogIds).forEach(catalogGroup => {
          //insert request
          catalogIds[catalogGroup].forEach(line => {
          var catalogIdEntry = {
            contract: { id: this.contract.contractId },
            sustainableSubcategory: { id: this.contract.sustainableSubCategoryId },
            // actions: [{ name: 'Margin Change', triggers: [] , reviews:[]}]
            actions: [{ name: 'Margin Change', triggers: [] }]
          };
          var scale = {};
          var review = {};
          
          if(!this.contract.editable && this.sortOrder.includes(line.kpiDescription)){
            scale['sortOrder'] = this.sortOrder.findIndex(ele => ele ===line.kpiDescription)
          }else{
            scale['sortOrder'] = this.checkUndefined(line,['kpiNumber']);
          } 
          scale['criteriaIdMinimum'] = this.checkUndefined(line,['minCriteria']);
          scale['criteriaValueMinimum'] = this.checkUndefined(line,['minValue']);
          scale['criteriaIdMaximum'] = this.checkUndefined(line,['maxCriteria']);
          scale['criteriaValueMaximum'] = this.checkUndefined(line,['maxValue']);
          scale['effectiveStartDate'] = this.checkUndefined(line,['effStartDate']);
          scale['effectiveEndDate'] = this.checkUndefined(line,['effEndDate']);
          scale['rate'] = this.checkUndefined(line,['priceImpact']);
          review['alertObligationDate'] = this.checkUndefined(line , ['alertObligationDate']);
          review['obligationDate'] = this.checkUndefined( line , ['obligationDate']);
          review['receptionDate'] = this.checkUndefined( line , ['receptDate']);
          var covenant = {
            amount : this.checkUndefined(line ,['alertsCovenantAmount'])
          };
          review['obligationReview']= {
            receptionStatusDescription : this.checkUndefined(line ,['statusObligationDesc']),
            covenant : covenant
          }
          var trigger = {
            scale: scale,
           reviews : [review]
          };
          if (line.catalogue) {
            catalogIdEntry.obligationType= { id: line.catalogue }
          }
          catalogIdEntry.actions[0].triggers.push(trigger);
          // catalogIdEntry.actions[0].reviews.push(review);
          catalogIdEntry.triggerCompliant = this.checkUndefined(line ,['triggerCompliant']);
          catalogIdEntry.extendedDescription = line.kpiDescription;
          catalogIdEntry.baselineTarget = this.isNanOrNull(line.target);
          catalogIdEntry.baselineYear = this.checkUndefined(line ,['baselineYear']);
          insertRequest.obligations.push(catalogIdEntry);
        });
      });
    }
    return insertRequest;
  }
  isNanOrNull (value){
    return Number.isNaN(Number.parseFloat(value)) ? undefined : value;
  }

  handleRowActions(event){
    const action = event.detail.action;
    const row = event.detail.row;
    switch (action.name) {
      case 'new_trigger':
        this.addTrigger(event);
          break;
      case 'delete':
        if(row.newRow){
          let rowIndex = this.dinamicData.findIndex(element => element === row);
          if(rowIndex > -1)this.dinamicData.splice(rowIndex, 1);
          let rowIndex2 = this.data.findIndex(element => element === row);
          if(rowIndex2 > -1)this.data.splice(index, 1);
        }
        this.deleteProcess(row);
          break;
    }
  }
  
    async deleteProcess(row){
      const result = await LightningConfirm.open({
        message: "Are you sure you want to delete this KPI?",
        variant: "default", // headerless
        label: "Delete a record"
      });
    if(result){
      try {
        deteleObligation ({scaleId : row.scaleId})
        .then(deleteResult => {
          if(this.dinamicData.length ===1){
            this.dinamicData = [];
            this.noData = true;
          }else{
            
              deteleObligation ({scaleId : row.scaleId})
              .then(deleteResult => {
        
                refreshObligation({
                  contract: this.contract.contractId,
                  category: this.contract.sustainableSubCategoryId,
        
                }).then(refreshedData => {
                  this.updateDataTable(refreshedData);
                  this.isLoading = false;
        
                }).catch(error => {
                  //exception handling
                  console.error(error);
                  this.error = error;
                  this.isLoading = false;
                });
              });
            } 
        }).catch(error =>{
          console.error(error);
          this.error = error;
          this.isLoading = false;
        });
      }catch (error) {
        console.error('Error deleting obligations', error.body.message);
      }

      
    }  
  }

  recallService(){
      if(this.sameRowDetail){
        refreshObligation({
          contract: this.contract.contractId,
          category: this.contract.sustainableSubCategoryId
        }).then(refreshedData => {
          this.updateDataTable(refreshedData);
          this.isLoading = false;
        })
      }
  }

  filterTable(event){
    var filterSelectedOptions =  [];
        if( event.detail.selectedValues.length === 0){
            this.dinamicData = this.data;
        }else{
          event.detail.selectedValues.forEach(filterOption => {
            filterSelectedOptions.push(filterOption.value);
          });
          if(this.data && filterSelectedOptions.length > 0){
            this.dinamicData = this.data.filter((dataElement) => filterSelectedOptions.includes(new Date(dataElement.alertObligationDate).getFullYear())) ;
          }
        }
    }

    doSorting(event) {
      // Get the field name and sort direction
      this.sortBy = event.detail.fieldName;
      this.sortedDirection = event.detail.sortDirection;
      console.log('this.sortedDirection ' + this.sortedDirection);
      this.sortData(this.sortBy, this.sortedDirection);

    }

    sortData(fieldname, direction) {
      let parseData = JSON.parse(JSON.stringify(this.data));
      // Return the value stored in the field
      let keyValue = (a) => {
          return a[fieldname];
      };
      // cheking reverse direction
      let isReverse = direction === 'asc' ? 1: -1;
      // sorting data
      parseData.sort((x, y) => {
          x = keyValue(x) ? keyValue(x) : ''; // handling null values
          y = keyValue(y) ? keyValue(y) : '';
          // sorting values based on direction
          return isReverse * ((x > y) - (y > x));
      });
      this.dinamicData = parseData;    
  }    
  pushUpdateError(){
    var errorsToPush = {};
    this.template.querySelector('c-kpi_custom_datatable').draftValues.forEach(row => {
      var constructedRow = this.dinamicData[row.id.substring(4)];
      if(!constructedRow.newRow){
        var rowErrorMess = ['No es posible actualizar el KPI, revise los datos e intentelo de nuevo'];
        var rowErrorField = ['kpiNumber'];
        errorsToPush[row.id] = {
          messages:rowErrorMess,
          fieldNames:rowErrorField,
          title:'Error en el servicio de actualizaciones'
        }
      }
    });
    this.errors = {
      rows:errorsToPush
    }
    const event = new ShowToastEvent({
      title:'Error en el servicio de creaciones',
      message:'No es posible crear el KPI, revise los datos e intentelo de nuevo',
    });
    this.dispatchEvent(event);
  }
  pushInsertError(){
    var errorsToPush = {};
    this.template.querySelector('c-kpi_custom_datatable').draftValues.forEach(row => {
      var constructedRow = this.dinamicData[row.id.substring(4)];
      if(constructedRow.newRow){
        var rowErrorMess = ['No es posible crear el KPI, revise los datos e intentelo de nuevo'];
        var rowErrorField = ['kpiNumber'];
        errorsToPush[row.id] = {
          messages:rowErrorMess,
          fieldNames:rowErrorField,
          title:'Error en el servicio de creaciones'
        }
      }
    });
    this.errors = {
      rows:errorsToPush
    }
    const event = new ShowToastEvent({
      title:'Error en el servicio de creaciones',
      message:'No es posible crear el KPI, revise los datos e intentelo de nuevo',
    });
    this.dispatchEvent(event);
  }
}