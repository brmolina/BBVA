import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getRecordUi, getFieldValue } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';

import STATUS_FIELD from '@salesforce/schema/DMT_Line__c.Status__c';
import LINE_ID_FIELD from '@salesforce/schema/DMT_Line__c.Line_Id__c';
import NAME_FIELD from '@salesforce/schema/DMT_Line__c.Name';

import OPP_ID_FIELD from '@salesforce/schema/Opportunity.DMT_Opp_Id__c';
import STAGE_FIELD from '@salesforce/schema/Opportunity.StageName';
import OPP_NAME_FIELD from '@salesforce/schema/Opportunity.Name';

import checkEditPermission from '@salesforce/apex/DMT_LineController.checkEditPermission';
import hasLineGodPermission from '@salesforce/customPermission/DMT_Line_God';
import getSnapshotEvaluationVersions from '@salesforce/apex/DMT_SnapshotEvaluationVersions.getSnapshotEvaluationVersions';
import fillLastGeneratedVersionField from '@salesforce/apex/DMT_SnapshotEvaluationVersions.fillLastGeneratedVersionField';
import processPostSnapshotEvaluationVersion from '@salesforce/apex/DMT_SnapshotEvaluationVersions.processPostSnapshotEvaluationVersion';
import sendEmailToApprovers from '@salesforce/apex/DMT_SnapshotEvaluationVersions.sendEmailToApprovers';
import getDMTUserId from '@salesforce/apex/DMT_SnapshotEvaluationVersions.getDMTUserId';
import generatePdfJSON from '@salesforce/apex/DMT_SnapshotEvaluationVersions.generatePdfJSON';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LOCALE from '@salesforce/i18n/locale';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

//Importing the custom Labels
import enteredAdditionalText from '@salesforce/label/c.dmt_cl_enterAdditionalDataText';
import versionDescriptionText from '@salesforce/label/c.dmt_cl_VersionDescriptionText';
import versionCategoryText from '@salesforce/label/c.dmt_cl_VersionCategoryText';

import DmtLineVersionsCompare from 'c/dmt_lineVersions_compare';

export default class DmtLineVersions extends LightningElement {

    channelName = '/event/DMT_LINES__e';
    subscription = {};

    pdfCacheMap = new Map();

    recordId;
    objectApiName; // Will hold "Opportunity" or "DMT_Line__c"
    @track wiredFields = []; // reactive field list for getRecord

    status;
    lineId;
    name;
    loggedInDmtUserId;

    showDefault = true;
    _showLineClosedView = false;

    @api 
    get showLineClosedView() {
      return this._showLineClosedView;
    }

    set showLineClosedView(value) {
      this._showLineClosedView =  (value === 'true' || value === true); 
      this.showDefault = false;
    }

    get compareDisabled() {
        return this.data.length < 2;
    }

    pdfData = null;
    showPdf = false;
    displayModal = false;

    isButtonDisabled = false;
    isLoading = true;
    loadingPDF = false;

    userInput = '';
    selectedCategory = 'User Defined'; // Default category for new versions
    selectedCategoryClosedView = 'Closed-Won';
    selectCategoryDisabled = true;

    //create custom Labels variable
    label = {versionCategoryText, versionDescriptionText, enteredAdditionalText};
    @track versionCategoryText = this.label.versionCategoryText;
    @track versionDescriptionText = this.label.versionDescriptionText;
    @track enteredAdditionalText = this.label.enteredAdditionalText;

    /* categoryOptions = [ ***** kept for future use if we start usign category catalog DMT_Taxonomy_Values__c*****
        { label: 'Type A', value: 'Category A' },
        { label: 'Type B', value: 'Category B' },
        { label: 'Type C', value: 'Category C' }
    ]; */

    // Global variables for pagination
    datatablePageSize = 10; // Number of items per page
    showPagination = false; // Determines if pagination should be displayed
    currentPage = 1; // Tracks the current page
    totalPages = 0; // Stores the total number of pages
    paginatedData = []; // Stores the data for the current page

    viewType = null;

    columns = [
        { label: 'View', type: 'button-icon', hideDefaultActions: true, initialWidth: 60 , cellAttributes: { style: 'text-align: center;' },
            typeAttributes: {
                iconName: 'action:preview',
                title: 'View',
                name: 'view',
                variant: 'border-filled',
                alternativeText: 'View',
             //   disabled: { fieldName: 'disablePreview' }
            }
        },
        { label: 'Description', fieldName: 'description', type: 'text', hideDefaultActions: true},
        { label: 'User', fieldName: 'user', type: 'text', hideDefaultActions: true, initialWidth: 130 },
        { label: 'Created Date', fieldName: 'createdDate', type: 'text', hideDefaultActions: true, initialWidth: 100 },
        { label: 'Category', fieldName: 'category', type: 'text', hideDefaultActions: true },
        { label: 'Version', fieldName: 'version', type: 'text', hideDefaultActions: true, initialWidth: 80 },
    ];

    data = [];

    selectedRows = [];

    connectedCallback() {
        this.registerErrorListener();
        this.handleSubscribe();
    }

    initializeViewType() {
     //   if (this.viewType) return; // Return early if already set

        switch (this.objectApiName) {
            case 'Opportunity':
                this.viewType = 'Opportunity';
                break;
            case 'DMT_Line__c':
                this.viewType = 'Line';
                break;
            default:
                console.warn('Unknown Object API Name:', this.objectApiName);
        }
    }

    async handleOpenCompare() {
        this.initializeViewType();
        const result = await DmtLineVersionsCompare.open({
            size: 'large', // Options: small, medium, large, full
            description: 'Comparison Modal',
            allVersions: this.data,
            lineId: this.lineId,
            viewType: this.viewType 
        });
        console.log('Modal closed with:', result);
    }

    handleSubscribe() {
        const messageCallback = (response) => {
            console.log('Received message: ', JSON.stringify(response));
            this.handleGetSnapshotEvaluationVersions();
        };

        subscribe(this.channelName, -1, messageCallback).then(response => {
            console.log('Subscribed to channel:', response.channel);
            this.subscription = response;
        });
    }

    registerErrorListener() {
        onError(error => {
            console.error('Emp API error:', error);
        });
    }

    @wire(getDMTUserId)
    getLoggedInDmtUserId({ error, data }) {
        if (data) {
            this.loggedInDmtUserId = data;
        } else if (error) {
            console.error('Error retrieving logged-in DMT user ID:', error);
        }
    }

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

            this.handleCheckEditPermission();
            this.handleGetSnapshotEvaluationVersions();

        } else if (error) {
            console.error('Error retrieving record:', error);
        }
    }

    handleCheckEditPermission() {
        if(this.status == 'Draft'){
            this.isButtonDisabled = true;
            return;
        }

        if (hasLineGodPermission) {
            console.warn('hasLineGodPermission:', hasLineGodPermission);
            this.isButtonDisabled = false;
            return;
        }

         checkEditPermission({ recordId: this.recordId })
            .then((result) => {
                const { isAdmin, accessLevel_edit } = result;
                this.isButtonDisabled = !(isAdmin || accessLevel_edit);
                console.log('isButtonDisabled:', this.isButtonDisabled);
            })
            .catch((error) => {
                console.error('Error determining button state:', error);
        });
    }

    handleGetSnapshotEvaluationVersions() {
      const payload = `opportunityId=${this.lineId}`;
        this.isLoading = true; // Show spinner
        getSnapshotEvaluationVersions({ requestStr: payload })
            .then((response) => {
             //   console.log('Response from getSnapshotEvaluationVersions:', response);
                const parsedResponse = JSON.parse(response);
                if (parsedResponse.success) {
                    const updatedData = parsedResponse.data.versions.map((version, index) => ({
                        id: (index + 1).toString(),
                        description: version.description,
                        user: version.user,
                        createdDate: this.formatDate(version.eventDate),
                        versionNumber: version.auditId,
                        category: version.categoryId,
                        version: version.id,
                        body: version.body
                    })).sort((a, b) => b.versionNumber - a.versionNumber); // Sort by versionNumber in descending order
                    this.setData([...updatedData]); // Use setData to update data and pagination
                    if(this.objectApiName === 'DMT_Line__c'){
                        if (parsedResponse.data.versions != null && parsedResponse.data.versions.length > 0) {
                           fillLastGeneratedVersionField({ LineId : this.lineId ,  description : updatedData[0].description,  category :  updatedData[0].category, version :  updatedData[0].version});
                        }
                    }
                    console.log('updatedData[0]: '+JSON.stringify(updatedData[0]));

                } else {
                    console.error('Error retrieving data from get snapshot evaluation versions, ', parsedResponse.errorMessage);
                    this.showToast('Error', 'Error in getSnapshotEvaluationVersions', 'error');
                }
            })
            .catch((error) => {
                console.error('Error in getSnapshotEvaluationVersions:', error);
                this.showToast('Error', 'Error in getSnapshotEvaluationVersions', 'error');
            })
            .finally(() => {
                this.isLoading = false; // Hide spinner
                this.handleCheckEditPermission(); // Recheck edit permission to re-enable the button
            });
    }

    renderedCallback() {
        if (this.showPrompt && !this.inputFocused) {
            const inputEl = this.template.querySelector('[data-id="versionInput"]');
            if (inputEl) {
                inputEl.focus();
                this.inputFocused = true;
            }
        }
    }

    async processCreateNewVersion() {
        const MAX_VERSIONS_TO_CHECK = 3; // Adjust this to control performance

        this.isButtonDisabled = true;
        this.isLoading = true;

        if (this.data.length === 0) {
            this.handleCreateNewVersion();
            return;
        }

        try {
            const actualPdfJSON = await this.handleGeneratePdfJSON();
            let isDataMatching = false;
            let toastMessage = '';

            // Loop through up to MAX_VERSIONS_TO_CHECK versions (oldest to newest or vice versa)
            const versionsToCheck = this.data.slice(0, MAX_VERSIONS_TO_CHECK);
            let payload;
            let savedPdfJSON;
            for (const item of versionsToCheck) {
                payload = this.generateGetSnapshotVersionPayload(item.version);
                savedPdfJSON = await this.handleGeVersionBody(payload);
                console.log('checking duplicate data for version:', item.version);
              //  console.log('savedPdfJSON, ', JSON.stringify(savedPdfJSON));
              //  console.log('actualPdfJSON, ', JSON.stringify(actualPdfJSON));
                if (JSON.stringify(actualPdfJSON) === JSON.stringify(savedPdfJSON)) {
                    isDataMatching = true;
                    toastMessage = `The version you are trying to create matches version ${item.version}.`;
                    break;
                }
            }

            if (isDataMatching) {
                this.showToast('Warning', toastMessage, 'warning');
                this.handleCheckEditPermission();
                this.isLoading = false;
                return;
            }

            // Proceed with creation if no matches found
            this.handleCreateNewVersion();

        } catch (error) {
            console.error('Error in processCreateNewVersion:', error.message);
            this.showToast('Warning', 'Failed validating duplicated data. Proceeding with create new version', 'warning');
            //this.handleCreateNewVersion(true);
        }
    }

    async handleGeVersionBody(payload) {
        console.log('Payload for getSnapshotEvaluationVersions:', payload);
        try {
            const response = await getSnapshotEvaluationVersions({ requestStr: payload });
            const parsedResponse = JSON.parse(response); // Parse the response string
            console.log('Response from getSnapshotEvaluationVersions for version body:', JSON.stringify(parsedResponse));
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

    handleUserInput(event){
        this.userInput = event.target.value;
    }

    // Method to focus the next input (category combobox) when Version Description input is committed
    focusCombobox() {
        const categoryInput = this.template.querySelector('[data-id="categoryInput"]');
        if (categoryInput) {
            categoryInput.focus();
        }
    }

    handleCategoryChange(event) {
        this.selectedCategory = event.detail.value;
    }

    // Method to focus the confirm button when Category combobox is committed
    focusConfirmButton() {
        // Find the OK button in the modal footer
        const confirmButton = this.template.querySelector('[data-id="dialogConfirmButton"]');
        if (confirmButton) {
            confirmButton.focus();
        }
    }

    handleDialogKeydown(event) {
        if (event.key === 'Tab') {
            const isShift = event.shiftKey;
            const activeElement = this.template.activeElement;
            const versionInput = this.template.querySelector('[data-id="versionInput"]');
            const categoryInput = this.template.querySelector('[data-id="categoryInput"]');
            const confirmButton = this.template.querySelector('[data-id="dialogConfirmButton"]');

            // If focus is on OK button and Tab (not Shift+Tab) is pressed, cycle to first input
            if (activeElement === confirmButton && !isShift) {
                event.preventDefault();
                if (versionInput) versionInput.focus();
            }
            // If focus is on versionInput and Shift+Tab is pressed, cycle to OK button
            else if (activeElement === versionInput && isShift) {
                event.preventDefault();
                if (confirmButton) confirmButton.focus();
            }
            // If focus is on categoryInput and Shift+Tab is pressed, cycle to versionInput
            else if (activeElement === categoryInput && isShift) {
                event.preventDefault();
                if (versionInput) versionInput.focus();
            }
            // If focus is on versionInput and Tab is pressed, move to categoryInput
            else if (activeElement === versionInput && !isShift) {
                event.preventDefault();
                if (categoryInput) categoryInput.focus();
                else if (confirmButton) confirmButton.focus();
            }
            // If focus is on categoryInput and Tab is pressed, move to OK button
            else if (activeElement === categoryInput && !isShift) {
                event.preventDefault();
                if (confirmButton) confirmButton.focus();
            }
        }
        if (event.key === 'Escape' || event.key === 'Esc') {
            event.preventDefault();
            this.closePrompt();
        }
    }

    closePrompt() {
        this.showPrompt = false;
        this.showLineClosedView = false;
        this.userInput = '';
     //   this.selectedCategory = '';
        this.inputFocused = false;
        this.isLoading = false; // Hide spinner
        this.handleCheckEditPermission(); // Recheck edit permission to re-enable the button
        // Use a resolver for the prompt, reject when closing so the transaction does not proceed:
        if (this.resolver && typeof this.resolver.reject === 'function') {
            this.resolver.reject('Prompt cancelled');
        }
        this.resolver = null;
    }

    showPrompt = false;
    resolver;

    showPromptWithInput() {
        this.showPrompt = true;

        return new Promise((resolve, reject) => {
            this.resolver = { resolve, reject };
        });
    }

    confirmPrompt() {
        this.showPrompt = false;
        this.resolver?.resolve(this.userInput);
        console.log('confirmPrompt: ');
    }

    inputFocused = false;

    async handleCreateNewVersion(event) {
        let actionSelected;
        if(event){
          actionSelected  = event.currentTarget.dataset.action;
        }

        

        if(this.showLineClosedView == false){
            let result;
            try {
                result = await this.showPromptWithInput();

            } catch (e) {
                return;
            }
            this.inputFocused = false;
        }else{
            this.isLoading = true;
            await new Promise(resolve => setTimeout(resolve, 2000));
        }

        const payload = JSON.stringify({
            opportunityId: this.lineId,
            user: this.loggedInDmtUserId/*  ?? this.dmtUserId */,
            categoryId:  this.showLineClosedView ? this.selectedCategoryClosedView : this.selectedCategory,
            versionDescription: this.userInput
        });
        
        this.userInput = ''; // Clear the input field after capturing the value

        let versionId;
        let body;
        /*let type;
              switch (this.objectApiName) {
                case 'Opportunity':
                    type = 'Opportunity';
                    break;
                case 'DMT_Line__c':
                    type = 'Line';
                    break;
            } */

        this.initializeViewType();


        processPostSnapshotEvaluationVersion({ requestStr: payload, recordId: this.recordId, type: this.viewType })
            .then((response) => {
                    console.log('Response from processPostSnapshotEvaluationVersion:', response);
                    const parsedResponse = JSON.parse(response);
                    if (parsedResponse.success) {
                        versionId = parsedResponse.data.versionId;
                        body = parsedResponse.data.body;
                        let toastMessage = `Version ${versionId} created successfully!`;
                        this.showToast('Success', toastMessage, 'success'); // Dispatch green toast event
                        this.handleGetSnapshotEvaluationVersions();
                    } else {
                        console.error('Error in processPostSnapshotEvaluationVersion:', parsedResponse.errorMessage);
                        this.showToast('Error', 'Error in processPostSnapshotEvaluationVersion', 'error'); // Show error toast
                    }
            })
            .catch((error) => {
                console.error('Error in processPostSnapshotEvaluationVersion:', error);
                this.showToast('Error', 'Error in processPostSnapshotEvaluationVersion', 'error');
            }).finally(async () => {
                    this.cachePdfForVersion(versionId, body);
                    this.handleCheckEditPermission(); // Recheck edit permission to re-enable the button
                    this.isLoading = false; // Hide spinner
                    if(this.showLineClosedView != false){
                        this.showLineClosedView = false;
                        if(actionSelected === 'sendMailVersion' ){
                            const pdfGenerator = this.template.querySelector('c-pdf-generator');
                            pdfGenerator.jsonData = JSON.parse(body);
                            pdfGenerator.fileName = this.name;
                            pdfGenerator.output = 'blob'; 
                            const pdfBlob = await pdfGenerator.generatePDF();
                            if (pdfBlob) {
                                await this.saveBase64Pdf(pdfBlob);
                            }        
                           
                        }
                        this.dispatchEvent(new CustomEvent('reloadCard', { detail: true, bubbles: true, composed: true }));
                    }     
            });

            
                    
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

    

    async cachePdfForVersion(versionId, body) {
        try {
            if (!this.pdfCacheMap.has(versionId)) {
                let parsedResponse;
                if(body !== null){
                    parsedResponse = JSON.parse(body);
                } else {
                    const payload = this.generateGetSnapshotVersionPayload(versionId);
                    console.log('Generated Payload:', payload);
                    const body = await this.handleGeVersionBody(payload);
                    parsedResponse = JSON.parse(body);
                }
                let base64PdfData;
                console.log('generating and caching pdf data for version:', versionId);
                base64PdfData = await this.generatePdf(parsedResponse);
                this.pdfCacheMap.set(versionId, base64PdfData);
            }
        } catch (e) {
            console.warn('Failed to cache PDF for version', versionId, e);
        }
    }

    async handleCreatePDF(event) {
        this.isLoading = true;
        this.loadingPDF = true;
        this.displayModal = true;

        const selectedRow = event.detail.row;
        console.log('selected row:', selectedRow);
        console.log('selected row versionId:', selectedRow.version);

        const versionId = selectedRow.version;

        try {
            let base64PdfData;
            if (this.pdfCacheMap.has(versionId)) {
                console.log('using cached pdf data');
                base64PdfData = this.pdfCacheMap.get(versionId);
            } else {
                console.log('generating new pdf data');
                const payload = this.generateGetSnapshotVersionPayload(versionId);
                const body = await this.handleGeVersionBody(payload);
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
            this.isLoading = false;
            this.loadingPDF = false;
        }
    }

    generateGetSnapshotVersionPayload(versionId){
        return `opportunityId=${this.lineId}&versionId=${versionId}`;
    }

    // retrieve json data for the PDF generation and/or validation on creation of new version
    async handleGeneratePdfJSON() {
        try {
            /* let type;
             switch (this.objectApiName) {
                case 'Opportunity':
                    type = 'Opportunity';
                    break;
                case 'DMT_Line__c':
                    type = 'Line';
                    break;
            } */
           this.initializeViewType();
            return await generatePdfJSON({ recordId: this.recordId, type: this.viewType });
        } catch (error) {
            console.error('Error in handleGeneratePdfJSON:', error);
            throw new Error('Failed to fetch JSON data.');
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

    async previewPdf(base64PdfData) {
        try {
            this.pdfData = base64PdfData;
            this.showPdf = true;

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

    closeModal() {
        console.log('Closing modal');
        this.showPdf = false;
        this.pdfData = null;
        this.displayModal = false;
        this.loadingPDF = false; // Hide loading spinner
        this.isLoading = false; // Hide loading spinner
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

    // Updates pagination logic when assigning data
    setData(data) {
        this.data = data;
        this.currentPage = 1;
        this.totalPages = Math.ceil(this.data.length / this.datatablePageSize);
        this.showPagination = this.totalPages > 1;
        this.updatePaginatedData();
        this.updatePaginationButtons();
    }

    // Helper method to update paginated data
    updatePaginatedData() {
        const start = (this.currentPage - 1) * this.datatablePageSize;
        const end = this.currentPage * this.datatablePageSize;
        this.paginatedData = this.data.slice(start, end);
    }

    // Helper method to update pagination buttons
    updatePaginationButtons() {
        this.disablePrevious = this.currentPage === 1;
        this.disableNext = this.currentPage === this.totalPages;
    }

    // Handles the "Previous" button click
    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePaginatedData();
            this.updatePaginationButtons();
        }
    }

    // Handles the "Next" button click
    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updatePaginatedData();
            this.updatePaginationButtons();
        }
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
}