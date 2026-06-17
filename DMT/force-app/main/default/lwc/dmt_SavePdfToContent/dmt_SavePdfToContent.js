import { LightningElement, track, wire } from 'lwc';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { getRecord, getRecordUi, getFieldValue } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import LINE_ID_FIELD from '@salesforce/schema/DMT_Line__c.Line_Id__c';
import NAME_FIELD from '@salesforce/schema/DMT_Line__c.Name';
import STATUS_FIELD from '@salesforce/schema/DMT_Line__c.Status__c';

import OPP_ID_FIELD from '@salesforce/schema/Opportunity.DMT_Opp_Id__c';
import STAGE_FIELD from '@salesforce/schema/Opportunity.StageName';
import OPP_NAME_FIELD from '@salesforce/schema/Opportunity.Name';

import getSnapshotEvaluationVersions from '@salesforce/apex/DMT_SnapshotEvaluationVersions.getSnapshotEvaluationVersions';
import sendEmailToApprovers from '@salesforce/apex/DMT_SnapshotEvaluationVersions.sendEmailToApprovers';

export default class Dmt_SavePdfToContent extends LightningElement {

    channelName = '/event/DMT_LINES__e';
    subscription = {}; 
    externalIdOppOrLine;
    name;
    createPDF;
    recordId;
    lineId;
    versionId;
    opportunityId;
    objectApiName; // Will hold "Opportunity" or "DMT_Line__c"
    @track wiredFields = []; // reactive field list for getRecord

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            // Check standard and custom state parameters
            this.recordId = currentPageReference.state?.recordId || currentPageReference.state?.c__recordId || currentPageReference.attributes?.recordId;
        }
    }
        // Step 1: Detect object type from recordId
        @wire(getRecordUi, { recordIds: '$recordId', layoutTypes: ['Full'], modes: ['View'] })
        wiredRecordUi({ error, data }) {
            if (data) {
                this.objectApiName = data.records[this.recordId].apiName;
                console.log('Detected object:', this.objectApiName);
                if (this.objectApiName === 'DMT_Line__c') {
                    this.wiredFields = [STATUS_FIELD, LINE_ID_FIELD, NAME_FIELD];
                } else if (this.objectApiName === 'Opportunity') {
                    this.wiredFields = [STAGE_FIELD, OPP_ID_FIELD, OPP_NAME_FIELD];
                }
            } else if (error) {
                console.error('Error retrieving object info:', error);
            }
        }
    
        // Step 2: wire record with dynamic fields
        @wire(getRecord, { recordId: '$recordId', fields: '$wiredFields' })
        wiredRecord({ error, data }) {
            if (data) {
                if (this.objectApiName === 'DMT_Line__c') {
                    this.status = getFieldValue(data, STATUS_FIELD);
                    this.lineId = getFieldValue(data, LINE_ID_FIELD);
                    this.name = getFieldValue(data, NAME_FIELD);
                } else if (this.objectApiName === 'Opportunity') {
                    this.status = getFieldValue(data, STAGE_FIELD);
                    this.lineId = getFieldValue(data, OPP_ID_FIELD);
                    this.name = getFieldValue(data, OPP_NAME_FIELD);
                }
    
            } else if (error) {
                console.error('Error retrieving record:', error);
            }
        }

    connectedCallback() {
        this.registerErrorListener();
        this.handleSubscribe();
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    handleSubscribe() {
        const messageCallback = (response) => {
    
            this.createPDF = response.data.payload.CreatePdf__c;
            this.versionId = response.data.payload.VersionId__c;
            this.opportunityId = response.data.payload.OpportunityId__c;
            console.log('Dentro  del canal.' + 'Vers', this.opportunityId + 'In Line ', this.lineId);


            if (this.createPDF && this.lineId == this.opportunityId) {
                this.handleCreatePDF();
            } else {
                console.warn('Evento recibido sin External ID, abortando proceso.');
            }
        };

        subscribe(this.channelName, -1, messageCallback).then(response => {
            console.log('Subscribed to channel savePdftoContnt:', response.channel);
            this.subscription = response;
        });
    }

    handleUnsubscribe() {
        unsubscribe(this.subscription, response => {
            console.log('Desuscrito del canal.');
        });
    }
    registerErrorListener() {
        onError(error => {
            console.error('Emp API error:', error);
        });
    }

    async handleCreatePDF() {
        const versionId = this.versionId;

        try {
            let base64PdfData;
            console.log('generating new pdf data in SavePdfToContent:');
            const payload = this.generateGetSnapshotVersionPayload(versionId);
            const body = await this.handleGeVersionBody(payload);
            const parsedResponse = JSON.parse(body);
            console.log('parsedResponse :', parsedResponse );
            base64PdfData = await this.handlerGeneratePdf(parsedResponse);
        } catch (error) {
            console.error('Error in handleCreatePDF in SavePdfToContent:', error.message);
   
        } finally {
        }
    }
    async handleGeVersionBody(payload) {
        try {
            const response = await getSnapshotEvaluationVersions({ requestStr: payload });
            const parsedResponse = JSON.parse(response); // Parse the response string
            if (parsedResponse.success) {
                return parsedResponse.data.versions[0].body; // Return the body of the first version
            } else {
                console.error('Error in handleGeVersionBody in SavePdfToContent: ', parsedResponse.errorMessage);
            }
        } catch (error) {
            console.error('Error in handleGeVersionBody in SavePdfToContent: ', error);
        }
    }
    generateGetSnapshotVersionPayload(versionId){
        return `opportunityId=${this.lineId}&versionId=${versionId}`;
    }
    
    async handlerGeneratePdf(parsedResponse) {
        try {
            const pdfGenerator = this.template.querySelector('c-pdf-generator');  
            if (!pdfGenerator) {
                console.error('Error: Componente c-pdf-generator no encontrado en el DOM in SavePdfToContent:');
                return;
            }
            pdfGenerator.jsonData = parsedResponse;
            pdfGenerator.fileName = this.name;
            pdfGenerator.output = 'blob';
            const pdfBlob = await pdfGenerator.generatePDF();         
            if (pdfBlob) {
                await this.saveBase64Pdf(pdfBlob);
            }
        } catch (error) {
            console.error('Error generando Blob del PDF in SavePdfToContent:', error);
        }
    }

    async saveBase64Pdf(pdfBlob) {
        try {
            const dataBase64 = await this.convertBlobToBase64(pdfBlob);
            const response = await sendEmailToApprovers({
                pdfBase64: dataBase64,
                lineId: this.recordId,
                lineName: this.name
            });
            console.log('Proceso finalizado in SavePdfToContent. PDF Guardado ID:', response);

        } catch (error) {
            console.error('Error guardando PDF in SavePdfToContent :', JSON.stringify(error));
        }
    }    

    convertBlobToBase64(blob) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onloadend = () => {
                const base64 = reader.result.split(',')[1];
                resolve(base64);
            };
            reader.onerror = reject;
            reader.readAsDataURL(blob);
        });
    }
}