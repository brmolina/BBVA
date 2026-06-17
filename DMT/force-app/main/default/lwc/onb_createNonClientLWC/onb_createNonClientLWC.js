import { api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import LightningModal from 'lightning/modal';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { CloseActionScreenEvent } from 'lightning/actions';

import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

// Custom Labels
import labelNewProspect from '@salesforce/label/c.NClient_lbl_NewProspect';
import labelCancel from '@salesforce/label/c.NClient_lbl_Cancel';
import labelBack from '@salesforce/label/c.NClient_lbl_Back';
import labelContinue from '@salesforce/label/c.NClient_lbl_Continue';
import labelFollowRequirements from '@salesforce/label/c.NClient_lbl_Please_Follow_The_Requirements';
import labelCheckSimilar from '@salesforce/label/c.Check_Similar_Name_Non_Client';
import labelClientName from '@salesforce/label/c.NClient_lbl_Client_Name';
import labelLei from '@salesforce/label/c.ONB_LEI';

// Métodos Apex
import getSimilarAccountName from '@salesforce/apex/NONC_New_NonClient_ctlr.getSimilarAccountName';
import getAllNamesSOSL from '@salesforce/apex/NONC_New_NonClient_ctlr.ONB_getAllNamesSOSL';

export default class Onb_createNonClientLWC extends NavigationMixin(LightningModal) {

    // ========= API / INPUTS =========
    @api recordId;
    @api recordTypeId;
    @api showFooter;
    @api header;
    @api isOnAccount = false;

    // ========= STATE =========
    @track clientName = '';
    @track clientLei = '';
    @track clientCif = '';
    @track className = 'rigth-position';
    @track similarAccounts = [];
    @track compararNames = '';

    @track showForm = true;
    @track showAccList = false;
    @track showWarning = false;
    @track noAccountsMsg = false;
    @track checkSimilarName = false;
    @track checkNoDuplicate = false;
    @track clickNoDuplicate = false;
    @track showModal = true;
    @track showModalAux = false;
    @track disableContinue = true;
    @track msg = '';

    // layout
    @track heightCalculation = 'check-similar-form';
    formFactor = 'DESKTOP';

    // labels
    labelCancel = labelCancel;
    labelBack = labelBack;
    labelContinue = labelContinue;
    labelFollowRequirements = labelFollowRequirements;
    labelCheckSimilar = labelCheckSimilar;
    labelClientName = labelClientName;
    labelLei = labelLei;

    // header
    @api headerText = labelNewProspect;

    // ========= LIFECYCLE =========
    connectedCallback() {
        this.formFactor = FORM_FACTOR === 'Large' ? 'DESKTOP' : FORM_FACTOR;
        this.heightCalculation = this.formFactor !== 'DESKTOP'
            ? 'check-similar-form mobile'
            : 'check-similar-form';
    }

    // ========= GETTERS PARA LA VISTA =========
    get isDesktop() {
        return this.formFactor === 'DESKTOP';
    }

    get modalContainerClass() {
        return this.isDesktop
            ? 'slds-modal__container'
            : 'slds-modal__container responsive_modal';
    }

    get scrollerWrapperClass() {
        return this.isDesktop ? 'sWrapDesktop' : 'sWrap';
    }

    get showCancel() {
        return !this.checkSimilarName && !this.checkNoDuplicate;
    }

    get showBack() {
        return this.checkSimilarName || this.checkNoDuplicate;
    }

    get leiMaxLength() {
        const field =
            this.objectInfo?.data?.fields?.lei_id__c;

        return field ? field.length : null;
    }

    get cifMaxLength() {
        const field = this.objectInfo?.data?.fields?.CIF_local__c;
        return field ? field.length : null;
    }


    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    objectInfo;

    // ========= HANDLERS DE INPUT =========
    async handleNameChange(event) {
        this.clientName = (event.target.value || '').trim();
        console.log(this.recordTypeId);
        this.disableContinue = true;
        this.showWarning = false;
        this.noAccountsMsg = false;
        this.similarAccounts = [];

        if (this.clientName && this.clientName.length >= 3) {
            try {
                await getSimilarAccountName({
                    searchName: this.clientName
                });
            } catch (e) {
            }
        }
    }

    handleLeiChange(event) {
        this.clientLei = (event.target.value || '').trim();

        this.disableContinue = true;
        this.showWarning = false;
        this.noAccountsMsg = false;
    }

    handleCifChange(event) {
        this.clientCif = (event.target.value || '').trim();

        this.disableContinue = true;
        this.showWarning = false;
        this.noAccountsMsg = false;
    }

    // ========= CONTRASTAR =========
    async handleContrast() {
        this.showWarning = false;
        this.noAccountsMsg = false;
        this.checkSimilarName = false;
        this.checkNoDuplicate = false;

        const name = (this.clientName || '').trim();
        const lei = (this.clientLei || '').trim();
        const cif = (this.clientCif || '').trim();

        if ((!name || name.length < 3) && !lei && !cif) {
            this.msg = 'You must fill Name, LEI or CIF to contrast';
            this.showWarning = true;
            this.disableContinue = true;
            return;
        }

        try {
            const response = await getAllNamesSOSL({
                searchName: name,
                searchLEI: lei,
                searchCIF: cif,
                isOnDesktop: this.formFactor
            });

            if (response) {
                const listRecords = this.processRecords(response, name);

                if (listRecords.length > 0) {
                    this.showWarning = true;
                    this.showAccList = true;
                    this.showForm = false;
                    this.similarAccounts = listRecords;
                    this.disableContinue = false;

                    let filters = [];
                    if (name) filters.push(`name "${name}"`);
                    if (lei) filters.push(`LEI "${lei}"`);
                    if (cif) filters.push(`CIF "${cif}"`);

                    this.msg = `There are already some accounts under the ${filters.join(' and ')}`;
                } else {
                    this.noAccountsMsg = true;
                    this.disableContinue = false;

                    let filters = [];
                    if (name) filters.push(`name "${name}"`);
                    if (lei) filters.push(`LEI "${lei}"`);
                    if (cif) filters.push(`CIF "${cif}"`);

                    this.msg = `No accounts were found under the ${filters.join(' and ')}`;
                }
            } else {
                this.noAccountsMsg = true;
                this.disableContinue = false;
                this.msg = 'No accounts were found.';
            }
        } catch (error) {
            this.showValidation = true;
            this.checkNoDuplicate = false;
            this.disableContinue = true;
            this.checkSimilarName = false;
            this.compararNames = '';
            this.showWarning = true;
            this.msg = error?.body?.message || error.message || 'Unexpected error while checking duplicates.';
        }
    }

    async handleContinue() {
        if (this.disableContinue) {
            return;
        }

        this.close({
            action: 'continue',
            payload: {
                clientName: this.clientName,
                clientLei: this.clientLei,
                clientCif: this.clientCif
            }
        });
    }


    // ========= PROCESADO DE RESULTADOS =========
    processRecords(rawResponse, clientName) {
        let resultArray = [];
        try {
            const parsed = JSON.parse(rawResponse);
            resultArray = Array.isArray(parsed) ? parsed : [];
        } catch (e) {
            return [];
        }

        const normalizedTextBox = this.normalizeString(clientName);
        let lResult = [];

        for (let i = 0; i < resultArray.length; i++) {
            const item = { ...resultArray[i] };
            const normalizedName = this.normalizeString(item.clientName || '');
            item.isExactName = normalizedTextBox && normalizedName === normalizedTextBox;

            if (item.isExactName) {
                this.compararNames = item.clientName;
                this.checkNoDuplicate = false;
                this.checkSimilarName = true;
            }

            lResult.push(item);
        }

        return lResult;
    }

    normalizeString(str) {
        if (!str) {
            return '';
        }
        let normalized = str
            .replace(/[^a-zA-Z0-9 ]/g, '')
            .toLowerCase()
            .replace(/ {2}/g, ' ')
            .trim();

        while (normalized.indexOf('  ') !== -1) {
            normalized = normalized.replace('  ', ' ');
        }
        return normalized;
    }

    // ========= BOTÓN BACK =========
    handleBack() {
        this.checkNoDuplicate = false;
        this.checkSimilarName = false;
        this.disableContinue = true;
        this.clickNoDuplicate = false;
        this.showWarning = false;
        this.showAccList = false;
        this.showForm = true;
    }

    // ========= CERRAR =========
    handleClose() {
        this.close({
            action: 'cancel'
        });
    }

    // ========= CONTINUAR / CREAR =========
    async handleSave() {
        const accName = this.clientName;
        const accLei = this.clientLei;

        const defaultValues = {
            Name: accName,
            lei_id__c: accLei
        };

        this.showModal = false;
        this.showModalAux = true;

    }

    handleLWCBack() {
        this.showModal = true;
        this.showModalAux = false;
    }

    encodeDefaultFieldValues(fieldValues) {
        return Object.keys(fieldValues)
            .map(field => `${field}=${encodeURIComponent(fieldValues[field])}`)
            .join(',');
    }
}