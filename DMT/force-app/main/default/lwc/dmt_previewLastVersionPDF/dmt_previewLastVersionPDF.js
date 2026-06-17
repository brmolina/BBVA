import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getRecordUi, getFieldValue } from 'lightning/uiRecordApi';
import getSnapshotEvaluationVersions from '@salesforce/apex/DMT_SnapshotEvaluationVersions.getSnapshotEvaluationVersions';
import STATUS_FIELD from '@salesforce/schema/DMT_Line__c.Status__c';
import LINE_ID_FIELD from '@salesforce/schema/DMT_Line__c.Line_Id__c';
import NAME_FIELD from '@salesforce/schema/DMT_Line__c.Name';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import OPP_ID_FIELD from '@salesforce/schema/Opportunity.DMT_Opp_Id__c';
import STAGE_FIELD from '@salesforce/schema/Opportunity.StageName';
import OPP_NAME_FIELD from '@salesforce/schema/Opportunity.Name';
import LOCALE from '@salesforce/i18n/locale';
import { CloseActionScreenEvent } from 'lightning/actions';


export default class Dmt_previewLastVersionPDF extends LightningElement {

    @api isLoading = false;
    data = [];
    totalRecords = 0;
    @api loadingPDF = false;
    pageSize = 10;
    currentPage = 1;
    @api displayModal = false;
    pdfCacheMap = new Map();
    @api showPdf = false;
    @api recordId;
    objectApiName; // Will hold "Opportunity" or "DMT_Line__c"
    @track wiredFields = []; // reactive field list for getRecord
    @api styleName = 'nonChargedpdfStyle';

    status;
    lineId;
    name;
    loggedInDmtUserId;


    handleGetSnapshotEvaluationVersions() {
        const payload = `opportunityId=${this.lineId}`;
        console.log('Payload for getSnapshotEvaluationVersions:', payload);
        this.isLoading = true; // Show spinner
        getSnapshotEvaluationVersions({ requestStr: payload })
            .then((response) => {
                //console.log('FINISHED getSnapshotEvaluationVersions: '+response);
             //   console.log('Response from getSnapshotEvaluationVersions:', response);
                const parsedResponse = JSON.parse(response);
                console.log('Parsed response:', JSON.stringify(parsedResponse));
                if (parsedResponse.success) {
                    console.log('Parsed success');
                    if(parsedResponse.data.versions != null  && parsedResponse.data.versions.length > 0){
                        console.log('DENTRO IF');
                        const updatedData = parsedResponse.data.versions.map((version, index) => ({
                            id: (index + 1).toString(),
                            description: version.description,
                            user: version.user,
                            createdDate: this.formatDate(version.eventDate),
                            versionNumber: version.auditId,
                            category: version.categoryId,
                            version: version.id,
                            body: version.body
                        })).sort((a, b) => b.versionNumber - a.versionNumber);
                        this.data = updatedData;
                    }
                    
                   
                    //console.log('Updated data:', JSON.stringify(this.data[0].version));
                    /*this.data = updatedData.data.versions[0];
                    this.handleCreatePDF(updatedData.data.versions[0].id);*/


                } else {
                    //console.error('Error retrieving data from get snapshot evaluation versions, ', parsedResponse.errorMessage);
                    this.showToast('Error', 'Error in getSnapshotEvaluationVersions', 'error');
                }
            })
            .catch((error) => {
                console.error('Error in getSnapshotEvaluationVersions:', error);
                this.showToast('Error', 'Error in getSnapshotEvaluationVersions', 'error');
            })
            .finally(() => {
                if(this.data != null && this.data.length > 0){
                    this.handleCreatePDF(this.data[0].version);
                }else{
                    this.dispatchEvent(new CloseActionScreenEvent());
                    this.showToast('Version', 'There is no version created yet', 'info');
                }
                
            });
    }

    // Step 1: Detect object type from recordId
    @wire(getRecordUi, { recordIds: '$recordId', layoutTypes: ['Full'], modes: ['View'] })
    wiredRecordUi({ error, data }) {
        if (data) {
            this.objectApiName = data.records[this.recordId].apiName;
            //console.log('Detected object:', this.objectApiName);
            if (this.objectApiName === 'DMT_Line__c') {
                this.wiredFields = [STATUS_FIELD, LINE_ID_FIELD, NAME_FIELD];
                //console.log('wiredFields:', JSON.stringify(STATUS_FIELD) +' '+JSON.stringify(LINE_ID_FIELD)+ ' '+JSON.stringify(NAME_FIELD));
                this.loggedInDmtUserId = this.recordId;
                //console.log('loggedInDmtUserId:', this.loggedInDmtUserId);
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
            
            this.handleGetSnapshotEvaluationVersions();

        } else if (error) {
            console.error('Error retrieving record:', error);
        }
    }

    generateGetSnapshotVersionPayload(versionId){
        return `opportunityId=${this.lineId}&versionId=${versionId}`;
    }

    formatDate(dateString) {
        const options = {
            day: 'numeric',
            month: 'short',
            year: 'numeric',
        };
        const formattedDate = new Date(dateString).toLocaleString(LOCALE, options);
        return formattedDate.replaceAll(/\ /g,'-').replace(/\,/g,'');
    }

    async handleCreatePDF(version) {
        this.isLoading = true;
        this.loadingPDF = true;
        this.displayModal = true;

      

        const versionId = version;
        //console.log('versionId:', JSON.stringify(versionId));
        try {
            let base64PdfData;
            if (this.pdfCacheMap.has(versionId)) {
                //console.log('using cached pdf data');
                base64PdfData = this.pdfCacheMap.get(versionId);
            } else {
                console.log('generating new pdf data');
                const payload = this.generateGetSnapshotVersionPayload(versionId); 
                //console.log('Payload for getSnapshotEvaluationVersions:', payload);
                const body = await this.handleGeVersionBody(payload);

                if (!body) {
                    console.log('Error retrieving data from get snapshot evaluation versions, no body');
                }
                const parsedResponse = JSON.parse(body);
                base64PdfData = await this.generatePdf(parsedResponse);
                this.pdfCacheMap.set(versionId, base64PdfData);
            }
            await this.previewPdf(base64PdfData);
        } catch (error) {
            console.error('Error in handleCreatePDF:', error.message);
            this.showToast('Error', 'Failed to create and preview PDF.', 'error');
            this.closeModal(); // Close the modal in case of error
        } finally {
            this.displayModal = false;
            this.loadingPDF = false; // Hide loading spinner
            this.isLoading = false; // Hide loading spinner
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

    closeModal() {
        //console.log('Closing modal');
        this.showPdf = false;
        this.pdfData = null;
        this.displayModal = false;
        this.loadingPDF = false; // Hide loading spinner
        this.isLoading = false; // Hide loading spinner
    }

     async previewPdf(base64PdfData) {
        try {
            this.pdfData = base64PdfData;
            this.showPdf = true;
            this.styleName = 'pdfStyle';

            // Wait for the DOM to render the previewPdf component
            await Promise.resolve();

            const previewPdf = this.template.querySelector('c-preview-pdf');
            if (previewPdf) {
                previewPdf.preview(this.pdfData);
            } else {
                console.error('previewPdf component not found.');
            }
        } catch (error) {
            console.error('Error in previewPdf:', error);
            throw new Error('Failed to preview PDF.');
        }
    }

    async generatePdf(parsedResponse) {
        try {
            const pdfGenerator = this.template.querySelector('c-pdf-generator');
            pdfGenerator.jsonData = parsedResponse;
            pdfGenerator.output = 'string';

            const pdfString = await pdfGenerator.generatePDF();
         //   console.log('PDF String:', pdfString);
            const base64PdfData = pdfString.split(',')[1]; // Extract Base64 data
            return base64PdfData;
        } catch (error) {
            console.error('Error in generatePdf:', error);
            throw new Error('Failed to generate PDF.');
        }
    }

    async handleGeVersionBody(payload) {
        console.log('Payload for getSnapshotEvaluationVersions:', payload);
        try {
            const response = await getSnapshotEvaluationVersions({ requestStr: payload });
            const parsedResponse = JSON.parse(response); // Parse the response string
            //console.log('Response from getSnapshotEvaluationVersions for version body:', JSON.stringify(parsedResponse));
            if (parsedResponse.success) {
              //  console.log('Parsed response body:', parsedResponse.data.versions[0].body);
                return parsedResponse.data.versions[0].body; // Return the body of the first version
            } else {
                console.error('Error in handleGeVersionBody: ', parsedResponse.errorMessage);
                throw new Error('Failed to retrieve latest version body.');
            }
        } catch (error) {
            console.error('Error in handleGeVersionBody:', error);
            throw new Error('Failed to retrieve latest version body.');
        }
    }

}