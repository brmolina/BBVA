import { LightningElement, api, wire, track } from 'lwc';
import lightningModal from 'lightning/modal';

import { getRecord, getRecordUi, getFieldValue } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';

import STATUS_FIELD from '@salesforce/schema/DMT_Line__c.Status__c';
import LINE_ID_FIELD from '@salesforce/schema/DMT_Line__c.Line_Id__c';
import NAME_FIELD from '@salesforce/schema/DMT_Line__c.Name';
import CLOSED_FIELD from '@salesforce/schema/DMT_Line__c.Closed__c';

import OPP_ID_FIELD from '@salesforce/schema/Opportunity.DMT_Opp_Id__c';
import STAGE_FIELD from '@salesforce/schema/Opportunity.StageName';
import OPP_NAME_FIELD from '@salesforce/schema/Opportunity.Name';

import checkEditPermission from '@salesforce/apex/DMT_LineController.checkEditPermission';
import hasLineGodPermission from '@salesforce/customPermission/DMT_Line_God';
import getSnapshotEvaluationVersions from '@salesforce/apex/DMT_SnapshotEvaluationVersions.getSnapshotEvaluationVersions';
import fillLastGeneratedVersionField from '@salesforce/apex/DMT_SnapshotEvaluationVersions.fillLastGeneratedVersionField';
import processPostSnapshotEvaluationVersion from '@salesforce/apex/DMT_SnapshotEvaluationVersions.processPostSnapshotEvaluationVersion';
import sendEmailToApprovers from '@salesforce/apex/DMT_SendEmailService.sendEmailToApprovers';
import getDMTUserId from '@salesforce/apex/DMT_SnapshotEvaluationVersions.getDMTUserId';
import generateVersionHtml from '@salesforce/apex/DMT_SnapshotEvaluationVersions.generateVersionHtml';
import getDocuments from '@salesforce/apex/DMT_CoreDocuments_Controller.getDocuments';
import downloadFileBase64 from '@salesforce/apex/DMT_CoreDocuments_Controller.downloadFileBase64';
import getSnapshotContentVersionHtml from '@salesforce/apex/DMT_SnapshotEvaluationVersions.getSnapshotContentVersionHtml';
import deleteSnapshotContentVersion from '@salesforce/apex/DMT_SnapshotEvaluationVersions.deleteSnapshotContentVersion';
import getUploadConfig from '@salesforce/apex/DMT_CoreDocuments_Controller.getUploadConfig';
import updateFileMetadataWithObjectCode from '@salesforce/apex/DMT_CoreDocuments_Controller.updateFileMetadataWithObjectCode';
import preparePdfAssets from '@salesforce/apex/DMT_PdfService.preparePdfAssets';
import generateFinalPdf from '@salesforce/apex/DMT_PdfService.generateFinalPdf';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LOCALE from '@salesforce/i18n/locale';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import DMT_Styles from '@salesforce/resourceUrl/DMT_Styles';
import { loadStyle } from 'lightning/platformResourceLoader';

//Importing the custom Labels
import enteredAdditionalText from '@salesforce/label/c.dmt_cl_enterAdditionalDataText';
import versionDescriptionText from '@salesforce/label/c.dmt_cl_VersionDescriptionText';
import versionCategoryText from '@salesforce/label/c.dmt_cl_VersionCategoryText';

export default class dmt_previewLastVersionPDF extends lightningModal {

    

    static CORE_DOC_242 = 'CO-OF-00242';

    channelName = '/event/DMT_LINES__e';
    subscription = {};

    pdfCacheMap = new Map();

    @api recordId;
    objectApiName; // Will hold "Opportunity" or "DMT_Line__c"
    @track wiredFields = []; // reactive field list for getRecord
    // Guards handleGetSnapshotEvaluationVersions() being called from multiple places
    // (wire refresh, platform events) from re-triggering the auto preview more than once.
    _autoPreviewTriggered = false;

    connectedCallback() {
        this.registerErrorListener();
        this.handleSubscribe();
    }

    // Punto de entrada requerido para Quick Actions tipo ScreenAction. Salesforce asigna
    // @api recordId y llama a este método al abrir la acción. La carga real se dispara
    // de forma reactiva por los @wire de abajo una vez recordId está disponible.
    @api
    invoke() {
        console.log('[dmt_previewLastVersionPDF] invoke() called — recordId:', this.recordId);
    }
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        // recordId normalmente lo rellena la Quick Action vía @api. Este wire queda solo
        // como fallback si no se hubiera asignado.
        if (currentPageReference && !this.recordId) {
            this.recordId = currentPageReference.state?.recordId || currentPageReference.state?.c__recordId || currentPageReference.attributes?.recordId;
        }
    }


    status;
    wonLostStatus; // DMT_Line__c.Closed__c value ('Won' or 'Lost'); not applicable to Opportunity
    lineId;
    name;
    loggedInDmtUserId;

    showDefault = true;
    _showLineClosedView = false;

    styleName = 'nonChargedpdfStyle';

    @api 
    get showLineClosedView() {
      return this._showLineClosedView;
    }

    set showLineClosedView(value) {
      this._showLineClosedView =  (value === 'true' || value === true); 
      this.showDefault = false;
    }

    get compareDisabled() {
        return this.versionsOnly.length < 2;
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


    // Global variables for pagination
    datatablePageSize = 10; // Number of items per page
    showPagination = false; // Determines if pagination should be displayed
    currentPage = 1; // Tracks the current page
    totalPages = 0; // Stores the total number of pages
    paginatedData = []; // Stores the data for the current page

    viewType = null;


    data = [];
    versionsOnly = [];
    // Maps each versionId to its CoreDocuments contentLocator so the eye-click knows
    // whether to download an already-uploaded PDF or generate one on the fly.
    coreDocVersionMap = new Map();
    // Tracks whether the CoreDocuments service responded successfully on the last list load.
    // false = CoreDocuments was DOWN → show error on eye-click instead of attempting generation.
    coreDocsAvailable = false;
    // Tracks in-flight background CoreDocuments availability polls started after version creation.
    // Keyed by versionId. Eye-click handler awaits the same promise rather than firing a new callout.
    _pendingPollPromises = new Map();

    selectedRows = [];

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
                this.wiredFields = [STATUS_FIELD, LINE_ID_FIELD, NAME_FIELD, CLOSED_FIELD];
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
                this.wonLostStatus = getFieldValue(data, CLOSED_FIELD);
            } else if (this.objectApiName === 'Opportunity') {
                this.status = getFieldValue(data, STAGE_FIELD);
                this.lineId = getFieldValue(data, OPP_ID_FIELD);
                this.name = getFieldValue(data, OPP_NAME_FIELD);
            }
            this.handleCheckEditPermission();
            this.handleGetSnapshotEvaluationVersions().then(() => this.autoPreviewLastVersion());

        } else if (error) {
            console.error('Error retrieving record:', error);
        }
    }

    autoPreviewLastVersion() {
        if (this._autoPreviewTriggered) {
            return;
        }
        this._autoPreviewTriggered = true;

        if (!this.versionsOnly.length) {
            this.showToast('Warning', 'No hay versiones generadas para previsualizar.', 'warning');
            return;
        }

        this.handleCreatePDF({ detail: { row: this.versionsOnly[0] } });
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

    async handleGetSnapshotEvaluationVersions() {
        console.log('[DMT_LineVersions] ▶ handleGetSnapshotEvaluationVersions — loading list for lineId:', this.lineId);
        this.isLoading = true;

        const payload = `opportunityId=${this.lineId}`;

        // Always fetch both in parallel: snapshot service for full metadata (description, category,
        // user, date) and CoreDocuments for the contentLocator map used at eye-click time.
        const [snapshotResult, coreDocsResult] = await Promise.allSettled([
            getSnapshotEvaluationVersions({ requestStr: payload }),
            this.getCoreDocRows242()
        ]);

        this.versionsOnly = [];
        this.coreDocVersionMap = new Map();

        if (snapshotResult.status === 'fulfilled') {
            try {
                const parsedResponse = JSON.parse(snapshotResult.value);
                if (parsedResponse.success) {
                    this.versionsOnly = parsedResponse.data.versions.map((version, index) => ({
                        id: `snapshot-${index + 1}`,
                        description: version.description,
                        user: version.user,
                        createdDate: this.formatDate(version.eventDate),
                        versionNumber: version.auditId,
                        category: version.categoryId,
                        version: version.id,
                        body: version.body,
                        sourceType: 'snapshot'
                    })).sort((a, b) => b.versionNumber - a.versionNumber);

                    console.log('[DMT_LineVersions] ✅ Snapshot versions loaded:', this.versionsOnly.length,
                        '| Latest:', this.versionsOnly[0]?.version, '| Category:', this.versionsOnly[0]?.category);

                    if (this.objectApiName === 'DMT_Line__c' && this.versionsOnly.length > 0) {
                        fillLastGeneratedVersionField({
                            LineId: this.lineId,
                            description: this.versionsOnly[0].description,
                            category: this.versionsOnly[0].category,
                            version: this.versionsOnly[0].version
                        });
                    }
                } else {
                    console.error('[DMT_LineVersions] ❌ getSnapshotEvaluationVersions error:', parsedResponse.errorMessage);
                    this.showToast('Error', 'Error in getSnapshotEvaluationVersions', 'error');
                }
            } catch (parseError) {
                console.error('[DMT_LineVersions] ❌ Failed to parse snapshot response:', parseError);
                this.showToast('Error', 'Error parsing snapshot versions', 'error');
            }
        } else {
            console.error('[DMT_LineVersions] ❌ getSnapshotEvaluationVersions rejected:', snapshotResult.reason);
            this.showToast('Error', 'Error in getSnapshotEvaluationVersions', 'error');
        }

        if (coreDocsResult.status === 'fulfilled') {
            this.coreDocsAvailable = true;
            for (const row of coreDocsResult.value) {
                if (row.version && row.contentLocator) {
                    this.coreDocVersionMap.set(row.version, row.contentLocator);
                }
            }
            console.log('[DMT_LineVersions] ✅ CoreDocuments PDF map built — versions with existing PDF:',
                this.coreDocVersionMap.size, '| Keys:', Array.from(this.coreDocVersionMap.keys()));
        } else {
            this.coreDocsAvailable = false;
            console.warn('[DMT_LineVersions] ⚠ CoreDocuments is DOWN or unreachable:', coreDocsResult.reason);
        }

        // Decorate each row with the PDF icon field now that coreDocVersionMap is populated.
        this.versionsOnly = this.versionsOnly.map(row => ({
            ...row,
            pdfIconName: this.coreDocVersionMap.has(row.version) ? 'doctype:pdf' : ''
        }));

        // List always shows snapshot rows only — full metadata (description, category, user) intact.
        this.setData(this.versionsOnly);
        this.isLoading = false;
        this.handleCheckEditPermission();
        console.log('[DMT_LineVersions] ✅ List ready — total rows:', this.versionsOnly.length,
            '| With CoreDocuments PDF:', this.coreDocVersionMap.size);
    }

    async getCoreDocRows242() {
        if (!this.lineId) {
            return [];
        }
        console.log('[DMT_LineVersions] getCoreDocRows242 called for lineId:', this.lineId);
        try {
            const response = await getDocuments({ folderCode: this.lineId });
            console.log('[DMT_LineVersions] getCoreDocRows242 response:', response);
            if (!response || !response.success || !Array.isArray(response.data)) {
                return [];
            }
            console.log('[DMT_LineVersions] getCoreDocRows242 mappedRows initialized.');
            const mappedRows = [];
            let index = 0;

            response.data.forEach(folder => {
                if (!folder.children || !Array.isArray(folder.children)) {
                    return;
                }
                console.log('[DMT_LineVersions] Processing folder:', folder);
                folder.children.forEach(child => {
                    console.log('[DMT_LineVersions] Processing child.objectCode:', child.objectCode+ ' | child.documentType: ' + child.documentType);
                    const targetCode = child.objectCode || child.documentType;
                    if (targetCode !== this.constructor.CORE_DOC_242) {
                        return;
                    }
                    console.log('[DMT_LineVersions] Target code matches CORE_DOC_242:', targetCode);
                    const fileName = child.objectName || '';
                    if (!this.isPdfFile(fileName)) {
                        return;
                    }
                    console.log('[DMT_LineVersions] File is a PDF:', fileName);
                    index += 1;
                    const fileInfo = this.parseCoreDocFileName(fileName);
                    mappedRows.push({
                        id: `core-${child.id || index}`,
                        description: fileInfo.description,
                        user: fileInfo.user,
                        createdDate: fileInfo.eventDate,
                        category: this.getAssessmentLabel(),
                        version: fileInfo.versionId,
                        sourceType: 'coreDoc',
                        contentLocator: child.contentLocator,
                        cleanName: fileInfo.description,
                        name: child.objectName
                    });
                });
            });
            console.log('[DMT_LineVersions] getCoreDocRows242 mappedRows completed. Total mapped rows:', mappedRows.length);

            return mappedRows.sort((a, b) => this.getDateSortValue(b.createdDate) - this.getDateSortValue(a.createdDate));
        } catch (error) {
            console.error('Error loading Core Docs CO-OF-00242:', error);
            console.log('error:',JSON.parse(JSON.stringify(error, Object.getOwnPropertyNames(error))));
            return [];
        }
    }

    getAssessmentLabel() {
        if (this.objectApiName === 'Opportunity') { return 'Opportunity Assessment';}
        if (this.objectApiName === 'DMT_Line__c') { return 'Line Assessment';}
        return 'Assessment';
    }

    async pollForVersionCoreDoc(versionId) {
        const MAX_RETRIES = 5;
        const DELAY_MS = 2000;
        for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
            await new Promise(resolve => setTimeout(resolve, DELAY_MS));
            try {
                const rows = await this.getCoreDocRows242();
                const found = rows.find(r => r.version === versionId);
                if (found) {
                    this.coreDocVersionMap.set(versionId, found.contentLocator);
                    this.updateRowPdfIcon(versionId, 'doctype:pdf');
                    console.log('[DMT_LineVersions] ✅ Poll: CoreDoc PDF found for version:', versionId);
                    return true;
                }
                console.info('[DMT_LineVersions] ℹ Poll attempt', attempt + 1, '— PDF not yet in CoreDocuments for version:', versionId);
            } catch (e) {
                console.warn('[DMT_LineVersions] ⚠ Poll attempt', attempt + 1, 'failed for version:', versionId, '—', e.message);
            }
        }
        console.info('[DMT_LineVersions] ℹ Poll exhausted for version:', versionId, '— eye-click fallback active if user opens PDF');
        return false;
    }

    updateRowPdfIcon(versionId, iconName) {
        this.versionsOnly = this.versionsOnly.map(row =>
            row.version === versionId ? { ...row, pdfIconName: iconName } : row
        );
        this.setData(this.versionsOnly);
    }


    parseCoreDocFileName(originalName) {
        const fallbackDescription =  'Gestor Documental' || 'N/A';
        const fallback = {
            description: fallbackDescription,
            versionId: this.constructor.CORE_DOC_242,
            eventDate: 'N/A',
            user: 'N/A'
        };

        if (!originalName) {
            return fallback;
        }

        const dotIndex = originalName.lastIndexOf('.');
        const baseName = dotIndex !== -1 ? originalName.substring(0, dotIndex) : originalName;
        const parts = baseName.split('_');

        if (parts.length < 4) {
            return fallback;
        }

        const user = parts[parts.length - 1] || 'N/A';
        const eventDateRaw = parts[parts.length - 2] || 'N/A';
        const versionId = parts[parts.length - 3] || this.constructor.CORE_DOC_242;
        const description = 'Gestor Documental'; //parts.slice(0, parts.length - 3).join('_') || fallbackDescription;

        return {
            description,
            versionId,
            eventDate: this.formatCoreDocEventDate(eventDateRaw),
            user
        };
    }

    formatCoreDocEventDate(eventDateRaw) {
        const parsedDate = this.parseCoreDocDate(eventDateRaw);
        if (!parsedDate) {
            return eventDateRaw || 'N/A';
        }

        const monthNames = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
        return `${parsedDate.day}-${monthNames[parsedDate.month - 1]}-${parsedDate.year}`;
    }

    getDateSortValue(dateString) {
        const parsedDate = this.parseCoreDocDate(dateString);
        if (!parsedDate) {
            return 0;
        }

        const dateObj = new Date(parsedDate.year, parsedDate.month - 1, parsedDate.day);
        return isNaN(dateObj.getTime()) ? 0 : dateObj.getTime();
    }

    parseCoreDocDate(rawValue) {
        if (!rawValue || rawValue === 'N/A') {
            return null;
        }

        const dateValue = rawValue.trim().toLowerCase();
        const monthMap = {jan: 1, feb: 2, mar: 3, apr: 4, may: 5, jun: 6, jul: 7, aug: 8, sep: 9, oct: 10, nov: 11, dec: 12};
        let match = dateValue.match(/^(\d{4})-(\d{2})-(\d{2})$/);
        if (match) {
            const year = Number(match[1]);
            const month = Number(match[2]);
            const day = Number(match[3]);
            if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
                return { year, month, day };
            }
        }

        match = dateValue.match(/^(\d{4})(\d{2})(\d{2})$/);
        if (match) {
            const year = Number(match[1]);
            const month = Number(match[2]);
            const day = Number(match[3]);
            if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
                return { year, month, day };
            }
        }

        match = dateValue.match(/^(\d{1,2})-([a-z]{3})-(\d{4})$/);
        if (match) {
            const day = Number(match[1]);
            const month = monthMap[match[2]];
            const year = Number(match[3]);
            if (month && day >= 1 && day <= 31) {
                return { year, month, day };
            }
        }

        match = dateValue.match(/^(\d{1,2})-(\d{1,2})-(\d{4})$/);
        if (match) {
            const day = Number(match[1]);
            const month = Number(match[2]);
            const year = Number(match[3]);
            if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
                return { year, month, day };
            }
        }

        const parsed = new Date(rawValue);
        if (!isNaN(parsed.getTime())) {
            return {
                year: parsed.getFullYear(),
                month: parsed.getMonth() + 1,
                day: parsed.getDate()
            };
        }

        return null;
    }

    renderedCallback() {
        if (this.showPrompt && !this.inputFocused) {
            const inputEl = this.template.querySelector('[data-id="versionInput"]');
            if (inputEl) {
                inputEl.focus();
                this.inputFocused = true;
            }
        }
        loadStyle(this, DMT_Styles);
    }

    async processCreateNewVersion() {
        const MAX_VERSIONS_TO_CHECK = 3;

        this.isButtonDisabled = true;
        this.isLoading = true;

        if (this.versionsOnly.length === 0) {
            this.handleCreateNewVersion();
            return;
        }

        try {
            this.initializeViewType();
            const fullResponse = await generateVersionHtml({ recordId: this.recordId, type: this.viewType });
            const currentHtml = JSON.parse(fullResponse)?.HTML;

            if (currentHtml) {
                for (const item of this.versionsOnly.slice(0, MAX_VERSIONS_TO_CHECK)) {
                    const savedBody = await this.handleGetVersionBody(this.generateGetSnapshotVersionPayload(item.version));
                    if (!savedBody || this.isJsonBody(savedBody)) {
                        continue; // Legacy JSON versions cannot be compared against HTML — skip
                    }
                    const savedHtml = JSON.parse(savedBody)?.html;
                    if (savedHtml && savedHtml === currentHtml) {
                        this.showToast('Warning', `Current data matches version ${item.version}. No new version was created.`, 'warning');
                        this.handleCheckEditPermission();
                        this.isLoading = false;
                        return;
                    }
                }
            }

            this.handleCreateNewVersion();
        } catch (error) {
            console.error('[DMT_LineVersions] processCreateNewVersion error:', error.message);
            this.showToast('Warning', 'Failed to validate duplicate. Proceeding with version creation.', 'warning');
            this.handleCreateNewVersion();
        }
    }

    async handleGetVersionBody(payload) {
        console.log('Payload for getSnapshotEvaluationVersions:', payload);
        try {
            const response = await getSnapshotEvaluationVersions({ requestStr: payload });
            const parsedResponse = JSON.parse(response); // Parse the response string
            console.log('Response from getSnapshotEvaluationVersions for version body:', JSON.stringify(parsedResponse));
            if (parsedResponse.success) {
              //  console.log('Parsed response body:', parsedResponse.data.versions[0].body);
                return parsedResponse.data.versions[0].body; // Return the body of the first version
            } else {
                console.error('Error in handleGetVersionBody: ', parsedResponse.errorMessage);
                throw new Error('Failed to retrieve latest version body.');
            }
        } catch (error) {
            console.error('Error in handleGetVersionBody:', error);
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
                // Prompt was cancelled (e.g., Esc pressed), so do not proceed
                return;
            }
            this.inputFocused = false; // Reset input focus state
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
                        // PDF generation + CoreDocuments upload is now handled server-side in
                        // DMT_SnapshotEvaluationVersions.postSnapshotEvaluationVersions (CIBGLOBALD-3731).
                        // The eye-click fallback in handleCreatePDF covers any Apex-side upload failures.
                        // Background poll: update the PDF icon once the async upload lands in CoreDocuments.
                        const pollPromise = this.pollForVersionCoreDoc(versionId);
                        this._pendingPollPromises.set(versionId, pollPromise);
                        pollPromise.finally(() => this._pendingPollPromises.delete(versionId));
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
                            let pdfBlob;
/*                             if (this.isJsonBody(body)) {
                                const pdfGenerator = this.template.querySelector('c-pdf-generator');
                                pdfGenerator.jsonData = JSON.parse(body);
                                pdfGenerator.fileName = this.name;
                                pdfGenerator.output = 'blob';
                                pdfBlob = await pdfGenerator.generatePDF();
                            } */
                            if(this.extractHtmlBody(body)){
                                pdfBlob = await this.generateServerPdfBlob(this.extractHtmlBody(body));
                            }
                            if (pdfBlob) {
                                await this.saveBase64Pdf(pdfBlob, versionId);
                            }

                        }
                        this.dispatchEvent(new CustomEvent('reloadCard', { detail: true, bubbles: true, composed: true }));
                    }     
            });

            
                    
        }

    async saveBase64Pdf(pdfBlob, versionId) {
        try {
            const fileName = `${this.name}_${versionId}_${this.formatDateForFilename(new Date())}_${this.loggedInDmtUserId || 'unknown'}`;
            // DMT_Line__c: Status__c only ever holds 'Closed' (never 'Closed Won'); Won/Lost lives in Closed__c.
            // Opportunity: StageName holds 'Closed Won'/'Closed Lost' directly.
            const isClosedWon = this.objectApiName === 'DMT_Line__c'
                ? this.status === 'Closed' && this.wonLostStatus === 'Won'
                : this.status === 'Closed Won';
            const dataBase64 = await this.convertBlobToBase64(pdfBlob);
            const response = await sendEmailToApprovers({
                pdfBase64: dataBase64,
                lineId: this.recordId,
                lineName: this.name,
                fileNameForCoreDocs: fileName,
                isClosedWon: isClosedWon
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
        if (!this.isJsonBody(body)) {
            return; // HTML versions: PDF is produced by generateAndUploadVersionPdf, not client-side jsPDF caching.
        }
        try {
            if (!this.pdfCacheMap.has(versionId)) {
                let parsedResponse;
                if(body !== null){
                    parsedResponse = JSON.parse(body);
                } else {
                    const payload = this.generateGetSnapshotVersionPayload(versionId);
                    console.log('Generated Payload:', payload);
                    const body = await this.handleGetVersionBody(payload);
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
        console.log('[DMT_LineVersions] ▶ handleCreatePDF called for event:', JSON.stringify(event));
        const selectedRow = event.detail.row;
        const versionId = selectedRow.version;

        this.isLoading = true;
        this.loadingPDF = true;
        this.displayModal = true;

        console.log('[DMT_LineVersions] 👁 Eye click — version:', versionId,
            '| CoreDocuments PDF in memory:', this.coreDocVersionMap.has(versionId),
            '| Body format:', this.isJsonBody(selectedRow.body) ? 'JSON (legacy)' : 'HTML (new)');

        try {
            // If a background availability poll is still in flight for this version, await it —
            // reuses the same callout instead of firing a redundant getCoreDocRows242.
            if (!this.coreDocVersionMap.has(versionId) && this._pendingPollPromises.has(versionId)) {
                console.log('[DMT_LineVersions] 🕐 Awaiting background poll for version:', versionId);
                await this._pendingPollPromises.get(versionId);
                // After poll resolves, coreDocVersionMap may now contain this versionId.
            }

            if (this.coreDocVersionMap.has(versionId)) {
                // PDF already uploaded to CoreDocuments — download and display directly.
                const contentLocator = this.coreDocVersionMap.get(versionId);
                console.log('[DMT_LineVersions] 📥 Downloading from CoreDocuments — contentLocator:', contentLocator);
                await this.downloadAndPreviewFromCoreDoc(contentLocator);

            } else if (!this.isJsonBody(selectedRow.body)) {
                // No CoreDocuments PDF for this version — check if CoreDocuments is even available.
                if (!this.coreDocsAvailable) {
                    throw new Error('CoreDocuments is unavailable. Cannot retrieve or generate the PDF at this time.');
                }

                // Listing endpoint does not include the body; fetch it via single-version call.
                let snapshotBody = selectedRow.body;
                if (!snapshotBody) {
                    console.log('[DMT_LineVersions] 🔄 Body not in listing — fetching from service for version:', versionId);
                    snapshotBody = await this.handleGetVersionBody(this.generateGetSnapshotVersionPayload(versionId));
                }
                if (!snapshotBody) {
                    throw new Error('Could not retrieve snapshot body for version ' + versionId + '.');
                }

                // Body was null in the listing — format was unknown until now.
                // Old pdfmake JSON versions also return null body in the listing; re-classify
                // after fetching to avoid passing undefined html to the server-side PDF generator.
                if (this.isJsonBody(snapshotBody)) {
                    console.log('[DMT_LineVersions] 🔧 Fetched body is legacy JSON — routing to client-side generation for version:', versionId);
                    const parsedResponse = JSON.parse(snapshotBody);
                    const base64PdfData = await this.generatePdf(parsedResponse);
                    this.pdfCacheMap.set(versionId, base64PdfData);
                    await this.previewPdf(base64PdfData);
                    this.uploadGeneratedPdfBlob(versionId, this.base64ToBlob(base64PdfData));
                    return;
                }

                // CoreDocuments is UP but has no PDF for this version yet.
                // Check full vs skinny body to decide how to get the HTML.
                const envelope = JSON.parse(snapshotBody);
                const isFull = envelope.full !== false; // true = full styled HTML in snapshot

                if (isFull) {
                    // 99% case: full HTML stored in snapshot — generate PDF directly from it.
                    console.log('[DMT_LineVersions] 📋 Full HTML in snapshot → generating PDF server-side...');
                    const pdfBlob = await this.generateServerPdfBlob(envelope.html);
                    await this.uploadPdfBlobToCoreDocuments(versionId, pdfBlob);
                    const base64PdfData = await this.convertBlobToBase64(pdfBlob);
                    await this.previewPdf(base64PdfData);
                    this.handleGetSnapshotEvaluationVersions();
                    console.log('[DMT_LineVersions] ✅ PDF generated from snapshot full HTML, uploaded to CoreDocuments.');
                } else {
                    // Skinny body → ContentVersion backup holds the full styled HTML.
                    console.log('[DMT_LineVersions] 🔍 Skinny snapshot → fetching full HTML from ContentVersion backup...');
                    const fullHtml = await getSnapshotContentVersionHtml({ recordId: this.recordId, versionId });
                    if (!fullHtml) {
                        throw new Error('ContentVersion backup not found for version ' + versionId + '. Cannot regenerate PDF.');
                    }
                    const pdfBlob = await this.generateServerPdfBlob(fullHtml);
                    await this.uploadPdfBlobToCoreDocuments(versionId, pdfBlob);
                    // Upload succeeded → delete the ContentVersion backup (no longer needed)
                    await deleteSnapshotContentVersion({ recordId: this.recordId, versionId });
                    const base64PdfData = await this.convertBlobToBase64(pdfBlob);
                    await this.previewPdf(base64PdfData);
                    this.handleGetSnapshotEvaluationVersions();
                    console.log('[DMT_LineVersions] ✅ PDF from ContentVersion backup uploaded to CoreDocuments, backup deleted.');
                }

            } else {
                // Legacy JSON body — generate client-side via jsPDF, upload to CoreDocuments, display.
                console.log('[DMT_LineVersions] 🔧 Legacy JSON body — generating PDF client-side...');
                let base64PdfData;
                if (this.pdfCacheMap.has(versionId)) {
                    console.log('[DMT_LineVersions]   Using cached client-side PDF for version:', versionId);
                    base64PdfData = this.pdfCacheMap.get(versionId);
                } else {
                    const payload = this.generateGetSnapshotVersionPayload(versionId);
                    const body = await this.handleGetVersionBody(payload);
                    const parsedResponse = JSON.parse(body);
                    base64PdfData = await this.generatePdf(parsedResponse);
                    this.pdfCacheMap.set(versionId, base64PdfData);
                    console.log('[DMT_LineVersions]   Client-side PDF generated for version:', versionId);
                }
                await this.previewPdf(base64PdfData);

                // Opportunistically upload so future clicks serve from CoreDocuments.
                console.log('[DMT_LineVersions]   Uploading legacy PDF to CoreDocuments for future fast-serve...');
                this.uploadGeneratedPdfBlob(versionId, this.base64ToBlob(base64PdfData));
            }
        } catch (error) {
            const msg = error?.message || error?.body?.message || JSON.stringify(error);
            console.error('[DMT_LineVersions] ❌ handleCreatePDF failed for version', versionId, ':', msg, error);
            this.showToast('Error', 'Failed to create and preview PDF.', 'error');
            this.closeModal();
        } finally {
            this.isLoading = false;
            this.loadingPDF = false;
        }
    }

    async downloadAndPreviewFromCoreDoc(contentLocator) {
        let lastError;
        for (let attempt = 0; attempt < 2; attempt++) {
            if (attempt > 0) {
                console.log('[DMT_LineVersions] ⏳ Retrying CoreDocuments download in 2s (attempt', attempt + 1, ')...');
                await new Promise(resolve => setTimeout(resolve, 2000));
            }
            try {
                const payload = await downloadFileBase64({ contentLocator });
                if (!payload || !payload.base64Data) {
                    throw new Error('No data received from CoreDocuments for contentLocator: ' + contentLocator);
                }
                await this.previewPdf(payload.base64Data);
                console.log('[DMT_LineVersions] ✅ CoreDocuments PDF downloaded and displayed.');
                return;
            } catch (e) {
                lastError = e;
                console.warn('[DMT_LineVersions] ⚠ Download attempt', attempt + 1, 'failed:',
                    e?.body?.message || e?.message || JSON.stringify(e));
            }
        }
        throw lastError;
    }

    async handleCoreDocRowAction(selectedRow) {
        try {
            this.isLoading = true;
            this.loadingPDF = true;
            this.displayModal = true;

            const payload = await downloadFileBase64({ contentLocator: selectedRow.contentLocator });
            if (!payload || !payload.base64Data) {
                throw new Error('No data received from Core Documents');
            }
            await this.previewPdf(payload.base64Data);
        } catch (error) {
            console.error('Error in handleCoreDocRowAction:', error);
            this.showToast('Error', 'Failed to process Core Document file.', 'error');
            this.closeModal();
        } finally {
            this.isLoading = false;
            this.loadingPDF = false;
        }
    }

    generateGetSnapshotVersionPayload(versionId){
        return `opportunityId=${this.lineId}&versionId=${versionId}`;
    }

    // retrieve current record HTML snapshot for version creation and duplicate detection
    async handleGenerateVersionHtml() {
        try {
           this.initializeViewType();
            return await generateVersionHtml({ recordId: this.recordId, type: this.viewType });
        } catch (error) {
            console.error('Error in handleGenerateVersionHtml:', error);
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
            console.log('Previewing PDF with base64 data:', base64PdfData);
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

    isPdfFile(fileName) {
        return !!fileName && fileName.toLowerCase().endsWith('.pdf');
    }

    isJsonBody(body) {
        if (!body) return false;
        try {
            const parsed = JSON.parse(body);
            // {"html":"..."} is the new HTML-envelope format — treat as HTML, not legacy pdfmake JSON
            if (parsed && typeof parsed === 'object' && typeof parsed.html === 'string') {
                return false;
            }
            return true;
        } catch (e) {
            return false;
        }
    }

    // Extracts the raw HTML string from a body that may be either:
    //   - a JSON envelope {"html":"..."} (new format)
    //   - a raw HTML string (transitional, shouldn't occur but handled defensively)
    extractHtmlBody(body) {
        try {
            const parsed = JSON.parse(body);
            if (parsed && parsed.html) return parsed.html;
        } catch (e) { /* fall through */ }
        return body;
    }

    base64ToBlob(base64) {
        const byteChars = atob(base64);
        const byteArray = new Uint8Array(byteChars.length);
        for (let i = 0; i < byteChars.length; i++) {
            byteArray[i] = byteChars.charCodeAt(i);
        }
        return new Blob([byteArray], { type: 'application/pdf' });
    }

    formatDateForFilename(date) {
        const yyyy = date.getFullYear();
        const mm = String(date.getMonth() + 1).padStart(2, '0');
        const dd = String(date.getDate()).padStart(2, '0');
        return `${yyyy}-${mm}-${dd}`;
    }

    // TX1 (preparePdfAssets) + TX2 (generateFinalPdf) — Blob.toPdf() server-side, mirrors
    // the proven pattern in dmt_CreateHTMLAndJSONForTask.generateServerPdf.
    async generateServerPdfBlob(htmlBody) {
        const prep = await preparePdfAssets({ originalHtml: htmlBody });
        const pdfBase64 = await generateFinalPdf({
            finalHtml: prep.modifiedHtml,
            docIds: prep.documentIds || []
        });
        return this.base64ToBlob(pdfBase64);
    }

    // Uploads an already-generated PDF Blob to CoreDocuments as CO-OF-00242, using the filename
    // convention parseCoreDocFileName already expects: {description}_{versionId}_{date}_{user}.pdf
    async uploadPdfBlobToCoreDocuments(versionId, pdfBlob) {
        const config = await getUploadConfig();
        const fileName = `Gestor Documental_${versionId}_${this.formatDateForFilename(new Date())}_${this.loggedInDmtUserId || 'unknown'}.pdf`;

        const formData = new FormData();
        formData.append('file', pdfBlob, fileName);
        formData.append('folderId', this.lineId);
        formData.append('folderCode', this.lineId);

        const response = await fetch(config.endpoint, {
            method: 'POST',
            headers: config.headers,
            body: formData
        });

        if (!response.ok) {
            const errorBody = await response.text();
            throw new Error(`HTTP Error: ${response.status} ${response.statusText} - ${errorBody}`);
        }

        const result = await response.json();
        if (!result || !result.data || !result.data.fileId) {
            throw new Error('Upload succeeded but CoreDocuments response is missing fileId.');
        }

        await updateFileMetadataWithObjectCode({
            fileId: result.data.fileId,
            fileName,
            docType: this.constructor.CORE_DOC_242,
            folderId: this.lineId,
            objectCode: this.constructor.CORE_DOC_242
        });
    }

    // HTML version path: generate the PDF server-side from HTML and upload it to CoreDocuments.
    // Used both eagerly at version creation and as the eye-click fallback when no CoreDocuments
    // PDF exists yet for a given version (creation-time upload failed/still in flight).
    async generateAndUploadVersionPdf(versionId, htmlBody) {
        const pdfBlob = await this.generateServerPdfBlob(htmlBody);
        await this.uploadPdfBlobToCoreDocuments(versionId, pdfBlob);
        await this.handleGetSnapshotEvaluationVersions();
        return pdfBlob;
    }

    // Legacy JSON version path: the PDF Blob already exists (from the client-side jsPDF flow) —
    // just cache it into CoreDocuments so this version becomes a 'coreDoc' row going forward.
    async uploadGeneratedPdfBlob(versionId, pdfBlob) {
        try {
            await this.uploadPdfBlobToCoreDocuments(versionId, pdfBlob);
            this.handleGetSnapshotEvaluationVersions();
        } catch (error) {
            console.error('Error uploading legacy PDF to CoreDocuments for version', versionId, error);
        }
    }

    closeModal() {
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