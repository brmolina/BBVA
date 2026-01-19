import { LightningElement, wire, track, api } from 'lwc';
import { getRecord, getFieldValue, createRecord, deleteRecord, updateRecord } from 'lightning/uiRecordApi';
import DMT_Styles from "@salesforce/resourceUrl/DMT_Styles";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { loadStyle } from "lightning/platformResourceLoader";
import getMockResponse from '@salesforce/apex/DMT_CalloutLine_Opp.getMockResponse';
import getMockProductsList from '@salesforce/apex/DMT_CalloutLine_Opp.getMockProductsList';


import OPPORTUNITY_NAME_FIELD from "@salesforce/schema/Opportunity.Name";
import PRODUCTS_ASSOCIATED_OPP_FIELD from "@salesforce/schema/Opportunity.gf_opportunity_product_desc__c";
import SANCTION_OPP_FIELD from "@salesforce/schema/Opportunity.DMT_Sanction__c";

export default class dmt_CalloutOpportunity extends LightningElement {
    @track lines = [];
    @track error;
    @track productOPP = [];
    @track currentStep = 1;
    @track opportunityName;
    @track selectedLineName = '';
    @track selectedLineId = '';
    @track productLines = [];
    @track incompleteRows = [];
    

    opportunityId = '006KG000005XMLvYAO';

    columnsStep1 = [
        { label: 'Line Name', fieldName: 'lineName', hideDefaultActions:true },
        { label: 'Line ID', fieldName: 'lineId', hideDefaultActions:true },
        { label: 'Record Type', fieldName: 'recordType', hideDefaultActions:true }
    ];

    get columnsStep2() {
        return [
            { label: this.opportunityName , fieldName: 'productNameOPP', hideDefaultActions:true },
            { label: this.selectedLineName , fieldName: 'lineName', hideDefaultActions:true, cellAttributes:{style: 'position:relative;z-index: 2'}, type: 'picklist',
                typeAttributes: { isDisabled : { fieldName: 'isDisabled' },
                placeholder: 'Select...', options: this.productLines, fieldName: 'productName' 
                , value: { fieldName: 'productName' } 
                , context: { fieldName: 'Id' }
            },cellAttributes:{class: {fieldName:'deriVisible'}}}
        ];
    }

    get isStepOne() {
        return this.currentStep == 1;
    }

    get isStepTwo() {
        return this.currentStep == 2;
    }
    

    //se extraen los productos asociados a la oportunidad
    @wire(getRecord, { recordId: '$opportunityId', fields: [PRODUCTS_ASSOCIATED_OPP_FIELD, OPPORTUNITY_NAME_FIELD] })
    wiredOpportunity({ error, data }) {
        if (data) {
            const opportunityProducts = getFieldValue(data, PRODUCTS_ASSOCIATED_OPP_FIELD);
            const opportunityName = getFieldValue(data, OPPORTUNITY_NAME_FIELD);
            this.opportunityName = opportunityName;

            if (opportunityProducts) {
                this.productOPP = opportunityProducts
                    .split(',')
                    .map((p, index) => ({
                        id: index + 1,
                        productNameOPP: p.trim()
                    }));
            } else {
                this.productOPP = [{ id: 1, productNameOPP: 'Sin productos' }];
            }
        } else if (error) {
            console.error('Error al obtener la oportunidad:', error);
        }
    }

    renderedCallback() {

      Promise.all([loadStyle(this, DMT_Styles)])
      .then(() => {
          console.log("Static Resource Loaded");
      })
      .catch(error => {
          console.log("error-", error);
      });
    }

    connectedCallback() {
        this.loadLines();
        this.loadProducts();
    }

    loadLines() {
        getMockResponse()
            .then(result => {
                this.lines = result.map(line => ({
                    ...line,
                    recordType: line.recordTypeName
                }));
                console.log('lines', this.lines);
            })
            .catch(error => {
                this.error = error;
                console.error('Error al cargar líneas:', error);
            });
    }

    loadProducts() {
        getMockProductsList()
            .then(result => {
                const productArray = result || [];

                this.products = productArray.map(product => ({
                    label: product.productName,
                    value: product.productName
                }));
                this.productLines = this.products;
                console.log('productLines:', this.productLines);
            })
            .catch(error => {
                console.error('Error al cargar productos mock:', error);
            });
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        console.log('Fila seleccionada:', selectedRows);

        if (selectedRows && selectedRows.length > 0) {
            this.selectedLineName = selectedRows[0].lineName;
            this.selectedLineId = selectedRows[0].lineId;
        } else {
            this.selectedLineName = '';
            this.selectedLineId = '';
        }

        const selectionEvent = new CustomEvent('linechange', { detail: selectedRows });
        this.dispatchEvent(selectionEvent);
    }

    /*handleCellChange(event) {
        const { row, fieldName, value } = event.detail;

        const index = this.productOPP.findIndex(r => r.id === row.id);
        if (index !== -1) {
            this.productOPP[index][fieldName] = value;
            this.productOPP = [...this.productOPP];
        }

        this.incompleteRows = this.productOPP.filter(r => !r.lineName || r.lineName.trim() === '');
        console.log('incompleteRows1:', this.incompleteRows.length);
    }*/

    handleSave() {
        /*const incompleteRows = this.productOPP.filter(row => !row.lineName || row.lineName.trim() === '');
        console.log('incompleteRows:', incompleteRows. length);
        if (incompleteRows.length > 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Todas las filas de la columna Line Name deben estar rellenas para guardar.',
                    variant: 'error'
                })
            );
            return;
        }*/

        const fields = {};
        fields['Id'] = this.opportunityId;
        fields[SANCTION_OPP_FIELD.fieldApiName] = this.selectedLineId;

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Éxito',
                        message: 'Los datos seleccionados se guardaron correctamente.',
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                console.error('Error al guardar la línea:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error al guardar',
                        message: error.body ? error.body.message : error.message,
                        variant: 'error'
                    })
                );
            });
    }


    goToNextStep() {
        if (!this.selectedLineId) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Debe seleccionar una línea para poder continuar.',
                    variant: 'error'
                })
            );
            return;
        }

        this.currentStep = 2;
    }

    goToPreviousStep() {
        this.currentStep = 1;
    }
}