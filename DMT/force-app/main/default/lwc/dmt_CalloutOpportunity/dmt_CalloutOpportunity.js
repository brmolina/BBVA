import { LightningElement, wire, track, api } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import pubsub from "omnistudio/pubsub";
import getLinesFromService from '@salesforce/apex/DMT_CalloutLine_Opp.getLinesFromService';
import getProductsFromService from '@salesforce/apex/DMT_CalloutLine_Opp.getProductsFromService';
import getRiskLineTerms from '@salesforce/apex/DMT_CalloutLine_Opp.getRiskLineTerms';
import getOpportunityLineItems from '@salesforce/apex/DMT_CalloutLine_Opp.getOpportunityLineItems';
import getLineSFId from '@salesforce/apex/DMT_CalloutLine_Opp.getLineSFId';

import OPPORTUNITY_NAME_FIELD from "@salesforce/schema/Opportunity.Name";
import PRODUCTS_ASSOCIATED_OPP_FIELD from "@salesforce/schema/Opportunity.gf_opportunity_product_desc__c";
import SANCTION_OPP_FIELD from "@salesforce/schema/Opportunity.DMT_Sanction__c";
import PRODUCTO_ASOCIADO_FIELD from '@salesforce/schema/OpportunityLineItem.DMT_Associated_Line_Product__c';

const EVT_CLOSE_LWC='close_lwc';
const EVENT_STRG = 'event';

const ERROR_OPP = 'Error retrieving opportunity:';
const ERROR_LINE = 'Error retrieving line:';
const ERROR_LINE_TERM = 'Error loading the risk line terms:';
const ERROR_LOADING_PRODUCTS  = 'Error loading products:';
const ERROR_LOADING_OPPLINEITEMS = 'Error loading OpportunityLineItems:';
const WARNING_SAVING_PRODUCTS = 'It cannot be saved. There are rows with the same selected value.';
const WARNING_NO_VALID_RECORDS = 'No valid records were found to update.';

const SELECT_LINE = 'You must select a line to continue.';
const PRODUCTS_ASSOCIATED= 'The products and the line were correctly associated.';


export default class dmt_CalloutOpportunity extends LightningElement {
    @track lines = [];
    @track error;
    @track productOPP = [];
    @track currentStep = 1;
    @track opportunityName;
    @track selectedLineName = '';
    @track selectedLineId = '';
    @track productLines = [];
    @track incompleteRows = ['start'];
    @track riskLineTerms = [];
    @track selectedRowIds = [];
    @track productListFromOpp = [];
    @track isSaving = false;
    @track columnsStep2 = [];
    _oppId;
    _customerId;
    _lineExternalId;
    
    //oppId = '006KG000005XKHBYA4';
    //customerId = 'ES0182031712901';
    @api
    set lineId(value) {
        this.selectedLineId = value;
    }

    get lineId() {
        return this.selectedLineId;
    }
    @api
    set lineExternalId(value) {
        this._lineExternalId = value;
        if(this.lines.length > 0){
            const selectedLine = this.lines.find(
                line => line.lineId === this._lineExternalId
            );
            if (selectedLine) {
                this.selectedRowIds = [selectedLine.lineId];
                this.selectedLineId = selectedLine.lineId;
                this.selectedLineName = selectedLine.lineName;
            } else {
                this.selectedRowIds = [];
            }
        }
        

    }

    get lineExternalId() {
        return this._lineExternalId;
    }

    @api
    set lineName(value) {
        this.selectedLineName = value;
        
    }

    get lineName() {
        return this.selectedLineName;
    }

    @api
    set oppId(value) {
        this._oppId = value;

        if (value) {
            this.validateOpportunityLineItems();
        }
    }

    get oppId() {
        return this._oppId;
    }

    @api
    set customerId(value) {
        this._customerId = value;
        if (value) {
            this.loadLines();
        }
    }

    get customerId() {
        return this._customerId;
    }

    columnsStep1 = [
        { label: 'Line Name', fieldName: 'lineName', hideDefaultActions:true },
        { label: 'Line ID', fieldName: 'lineId', hideDefaultActions:true },
        { label: 'Record Type', fieldName: 'recordType', hideDefaultActions:true }
    ];

    get isStepOne() {
        return this.currentStep == 1;
    }

    get isStepTwo() {
        return this.currentStep == 2;
    }
    
    get canSave() {
        return this.incompleteRows.length == 0;
    }

    @wire(getRecord, { recordId: '$oppId', fields: [PRODUCTS_ASSOCIATED_OPP_FIELD, OPPORTUNITY_NAME_FIELD] })
    wiredOpportunity({ error, data }) {
        if (data) {
            const opportunityProducts = getFieldValue(data, PRODUCTS_ASSOCIATED_OPP_FIELD);
            const opportunityName = getFieldValue(data, OPPORTUNITY_NAME_FIELD);
            this.opportunityName = opportunityName;

            if (opportunityProducts) {
                this.productListFromOpp = opportunityProducts
                    .split(',')
                    .map((p, index) => ({
                        id: index + 1,
                        productNameOPP: p.trim()
                    }));
            } else {
                this.productListFromOpp = [{ id: 1, productNameOPP: 'Sin productos' }];
            }
        } else if (error) {
            console.error(ERROR_OPP, error);
        }
    }

    async validateOpportunityLineItems(){
        try {
            await this.loadOpportunityLineItems();

            if (!this.productOPP || this.productOPP.length === 0) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: '',
                        message: 'It is necessary to add products before associating a line.',
                        variant: 'error'
                    })
                );

                pubsub.fire(EVT_CLOSE_LWC, EVENT_STRG);
                return;
            }

            this.currentStep = 1;

        } catch (error) {
            console.error(error);
        }
    }

    updateDataValues(updateItem) {
        let copyData = this.copiarLista(this.productOPP);
        copyData.forEach(item => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                }
            }
        });
        this.dispatchEvent(new CustomEvent('tableProductChanges',  { bubbles:true, composed:true,detail:  copyData} ));
    }

    updateDraftValues(updateItem) {
        let draftValueChanged = false;
        let copyDraftValues = [...this.draftValues];

        copyDraftValues.forEach(item => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                }
                draftValueChanged = true;
            }
        });

        if (draftValueChanged) {
            this.draftValues = [...copyDraftValues];
        } else {
            this.draftValues = [...copyDraftValues, updateItem];
        }
    }

    picklistChanged(event) {
        event.stopPropagation();

        const data = event.detail.data;
        const rowId = data.context;
        const value = data.value;
        console.log('VALUE PICKLIST CHANGE: ' + JSON.stringify(this.productOPP))
        this.productOPP = this.productOPP.map(row => {
            if (row.id == rowId) {
                return { ...row, lineName: value };
            }
            return row;
        });

        this.incompleteRows = this.productOPP.filter(
            row => !row.lineName || row.lineName.trim() === ''
        );
    }

    handleCellChange(event) {
        this.updateDraftValues(event.detail.draftValues[0]);
    }

    loadLines() {
        this.isSaving = true;

        return getLinesFromService({ customerId: this.customerId })
            .then(result => {
                this.lines = result.map(line => {
                        return {
                            ...line,
                            recordType: line.recordTypeName
                        };
                    
                    
                });
                if (!this.lines || this.lines.length === 0) {
                    this.showToast('No se han encontrado líneas', 'warning');
                    pubsub.fire(EVT_CLOSE_LWC, EVENT_STRG);
                    return; // Salimos para no continuar con la selección
                }
                if (this._lineExternalId) {

                    const selectedLine = this.lines.find(line => {
                        const match = line.lineId === this._lineExternalId;
                        return match;
                    });

                    if (selectedLine) {
                        this.selectedRowIds = [selectedLine.lineId];
                        this.selectedLineId = selectedLine.lineId;
                        this.selectedLineName = selectedLine.lineName;

                    } else {
                        this.selectedRowIds = [];
                    }
                }
            })
        .catch(error => {
            this.error = error;
            console.error(ERROR_LINE, error);
        })
        .finally(() => {

            this.isSaving = false;
        });
    }

    loadProducts(lineExternalId) {
        return getProductsFromService({ lineId: lineExternalId })
        .then(result => {
            const productArray = result || [];

            this.productLines = productArray.map(product => ({
                label: product.productName,
                value: product.productName,
                priorityId: product.priorityId
            }));
            
            this.columnsStep2 = [
                { label: this.opportunityName , fieldName: 'productNameOPP', hideDefaultActions:true }, 
                { label: this.selectedLineName , fieldName: 'lineName', hideDefaultActions:true, type: 'picklist', 
                    typeAttributes: { isDisabled : { fieldName: 'isDisabled' }, placeholder: 'Select...', 
                    options: this.productLines, fieldName: 'productName' , 
                    value: { fieldName: 'productName' } , 
                    context: { fieldName: 'id' } },
                    cellAttributes:{class: {fieldName:'deriVisible'}}
                }
            ];
        })
        .catch(error => {
            console.error(ERROR_LOADING_PRODUCTS, error);
        });
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        console.log('selectedRows2: ' + JSON.stringify(selectedRows))
        if (selectedRows && selectedRows.length > 0) {
            this.selectedLineName = selectedRows[0].lineName;
            this.selectedLineId = selectedRows[0].lineId;
            this.selectedRowIds = [this.selectedLineId];

            this.loadRiskLineTerms(this.selectedLineId);
            this.loadProducts(this.selectedLineId);
        } else {
            this.selectedLineName = '';
            this.selectedLineId = '';
        }

        const selectionEvent = new CustomEvent('linechange', { detail: selectedRows });
        this.dispatchEvent(selectionEvent);
        this.loadProducts(this.selectedLineId);
    }

    loadRiskLineTerms(lineExternalId) {
        getRiskLineTerms({ lineExternalId })
            .then(result => {
                this.riskLineTerms = result.map(rlt => ({
                    riskLineTermId: rlt.Id,
                    priorityId: rlt.gf_group_priority_line_id__c
                }));
            })
            .catch(error => {
                console.error(ERROR_LINE_TERM, error);
            });
    }

    loadOpportunityLineItems() {
        return getOpportunityLineItems({ oppId: this.oppId })
            .then(result => {


                this.productOPP = result.map(prod => ({
                    oppItemId: prod.Id,
                    productNameOPP: prod.Product2?.Name,
                    productName: this.productLines.find(
                        pl => pl.priorityId === prod.DMT_Associated_Line_Product__r?.gf_group_priority_line_id__c
                    )?.label || '' 
                }));

                return this.productOPP;
            })
            .catch(error => {
                console.error(ERROR_LOADING_OPPLINEITEMS, error);
            });
    }

    async handleSave() {
        const selectedValues = new Set();
        let hasDuplicates = false;
        
        this.productListFromOpp.forEach(row => {
            const value = row.lineName?.trim();
            if (value) {
                if (selectedValues.has(value)) {
                    hasDuplicates = true;
                } else {
                    selectedValues.add(value);
                }
            }
        });

        if (hasDuplicates) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: '',
                    message: WARNING_SAVING_PRODUCTS,
                    variant: 'warning'
                })
            );
            return;
        }

        this.isSaving = true;

        try {
            // Paso 1️: si no hay riskLineTerms cargados, los traemos
            if (!this.riskLineTerms || this.riskLineTerms.length === 0) {
                const result = await getRiskLineTerms({ lineExternalId: this.selectedLineId });
                this.riskLineTerms = result.map(rlt => ({
                    riskLineTermId: rlt.Id,
                    priorityId: rlt.gf_group_priority_line_id__c
                }));
            }
            // Paso 2️: construir las actualizaciones
            const updates = this.productOPP.map((prodOPP, index) => {

                const prodLine = this.productLines[index];
                if (!prodLine) return null;
                console.log('prodLine: ' + JSON.stringify(prodLine));
                const matchedRiskTerm = this.riskLineTerms.find(
                    rlt => rlt.priorityId === prodLine.priorityId
                );

                if (!matchedRiskTerm) return null;

                return {
                    fields: {
                        Id: prodOPP.oppItemId,
                        [PRODUCTO_ASOCIADO_FIELD.fieldApiName]: matchedRiskTerm.riskLineTermId
                    }
                };
            }).filter(u => u !== null);

            // Paso 3️: ejecutar las actualizaciones en Salesforce
            if (updates.length === 0) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: '',
                        message: WARNING_NO_VALID_RECORDS,
                        variant: 'warning'
                    })
                );
                return;
            }

            await Promise.all(updates.map(updateRecord));

            const sflineId = await getLineSFId({ lineExternalId: this.selectedLineId });

            const fields = {};
            fields['Id'] = this.oppId;
            fields[SANCTION_OPP_FIELD.fieldApiName] = sflineId;

            const recordInput = { fields };
            
            await updateRecord(recordInput);
            
            this.dispatchEvent(
                new ShowToastEvent({
                    title: '',
                    message: PRODUCTS_ASSOCIATED,
                    variant: 'success'
                })
            );
            pubsub.fire(EVT_CLOSE_LWC, EVENT_STRG);

        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: '',
                    message: error.body ? error.body.message : error.message,
                    variant: 'error'
                })
            );
        } finally {
            this.isSaving = false;
            pubsub.fire(EVT_CLOSE_LWC, {
                lineId: this.selectedLineId,
                lineName: this.selectedLineName
            });
        }
    }

    copiarLista(listaOriginal) {
        return listaOriginal.map(elemento => {
          if (typeof elemento === 'object' && elemento !== null) {
            return JSON.parse(JSON.stringify(elemento));
          } else {
            return elemento;
          }
        });
      }

    async goToNextStep() {
        if (!this.selectedLineId) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: '',
                    message: SELECT_LINE,
                    variant: 'error'
                })
            );
            return;
        }

        this.isSaving = true;

        try {
            await this.loadProducts(this.selectedLineId);
            await this.loadRiskLineTerms(this.selectedLineId);
            await this.loadOpportunityLineItems();
            this.currentStep = 2;

        } finally {
            this.isSaving = false;
        }

    }

    goToPreviousStep() {
        this.currentStep = 1;
    }
    handleCancer() {
        pubsub.fire(EVT_CLOSE_LWC, EVENT_STRG);
    }
    async connectedCallback() {
        this.loadOpportunityLineItems();
    }
    showToast(message, variant = 'info') {
        const event = new ShowToastEvent({
            title: 'Aviso',
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

}