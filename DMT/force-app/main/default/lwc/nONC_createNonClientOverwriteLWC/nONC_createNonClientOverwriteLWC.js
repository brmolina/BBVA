/*CAMBIOS MIGRACIÓN A LWC GLOBAL BANKER*/
import { api, LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getFieldSetFromAccount from '@salesforce/apex/NONC_EditFormNonClient_ctlr.getFieldSetFromAccount';
import getHelpText from '@salesforce/apex/NONC_EditFormNonClient_ctlr.getHelpText';
import validateNonClienteComponent from '@salesforce/apex/NONC_EditFormNonClient_ctlr.validateNonClienteComponent';
import createNewAccountNew from '@salesforce/apex/NONC_EditFormNonClient_ctlr.createNewAccountNew';
import getFieldLookup from '@salesforce/apex/NONC_EditFormNonClient_ctlr.getFieldLookup';
import getFieldSetProspectSubsidiary from '@salesforce/apex/NONC_EditFormNonClient_ctlr.getFieldSetProspectSubsidiary';

import LABEL_BACK from '@salesforce/label/c.NClient_lbl_Back';
import LABEL_SAVE from '@salesforce/label/c.NClient_lbl_Save';
import LABEL_CLOSE from '@salesforce/label/c.NClient_lbl_Close';
import LABEL_CONTACT_ADMIN from '@salesforce/label/c.Contact_your_Admin';
import LABEL_CREATE_NON from '@salesforce/label/c.Create_Non';
import { getPicklistValues, getObjectInfos } from "lightning/uiObjectInfoApi";
import CM_FIELD from "@salesforce/schema/Account.DES_Country_of_Management_OLD__c";
import ACCOUNT_OBJECT from '@salesforce/schema/Account';

export default class NONCCreateNonClientOverwriteLWC extends NavigationMixin(LightningElement) {
    @track subsidiaryTaxId = '';

    handleSubsidiaryTaxIdChange(event) {
        this.subsidiaryTaxId = event.target.value;
    }

    @wire(getPicklistValues, { recordTypeId: '$prospectSubsidiaryRecordTypeId', fieldApiName: CM_FIELD })
    wiredPicklistValues({ data, error }) {
        if (data) {
            this._subsidiaryCountryManagement = data.values;
            console.log('Loaded picklist values for Country of Management:', data);
        } else if (error) {
            console.error('Error loading picklist values', error);
        }
    }

    @wire(getObjectInfos, { objectApiNames: [ACCOUNT_OBJECT] })
    wiredObjectInfos({ data, error }) {
        if (data) {
            this.objectInfos = data;
            const rtInfos = data.results?.[0]?.result?.recordTypeInfos || {};
            const rtEntries = Object.entries(rtInfos);
            const subsidiaryEntry = rtEntries.find(([, info]) => info.name === 'Prospect Subsidiary');
            const groupEntry = rtEntries.find(([, info]) => info.name === 'Prospect Group');
            this.prospectSubsidiaryRecordTypeId = subsidiaryEntry?.[0] ?? null;
            this.prospectGroupRecordTypeId = groupEntry?.[0] ?? null;
        } else if (error) {
            console.error('Error loading object infos', error);
        }
    }

    @api headerText = 'New Prospect';
    @api isOnAccount = false;
    @api isAdditionalRT = false;
    @api clientName = '';
    @api getDataFirstScreen = '';

    labels = {
        back: LABEL_BACK,
        save: LABEL_SAVE,
        close: LABEL_CLOSE,
        contactAdmin: LABEL_CONTACT_ADMIN,
        createNon: LABEL_CREATE_NON
    };

    @track columns = [];
    @track customIdsResponse = {};
    @track helpText = '';
    @track loadError;
    @track isLoading = true;
    @track isSaving = false;
    @track recordId;
    @track recordTypeId;
    @track lookupConfig = null;
    @track selectedLookupRecord = null;

    // Checkbox Matrix solo para pantalla de creación de prospect subsidiary
    @track isMatrix = false;
    @track isMobile = false;

    // CAMBIOS MIGRACIÓN A LWC GLOBAL BANKER — Prospect Subsidiary conditional section
    prospectSubsidiaryToggleLabel = 'Create Prospect Parent Subsidiary';
    prospectSubsidiarySectionTitle = 'Create Prospect Subsidiary - Parent';
    @track showProspectSubsidiarySection = false;
    @track prospectSubsidiaryFields = [];
    @track isLoadingSubsidiaryFields = false;
    prospectSubsidiaryFieldsLoaded = false;
    prospectSubsidiaryRecordTypeId = null;
    prospectGroupRecordTypeId = null;

    connectedCallback() {
        this.detectMobileDevice();
        this.loadFormContext();
        // Precargar campos de subsidiaria al cargar la página
        this.loadProspectSubsidiaryFields();
    }

    get objectApiName() {
        return ACCOUNT_OBJECT;
    }

    get hasLoadError() {
        return Boolean(this.loadError);
    }

    get isReady() {
        return !this.isLoading && !this.hasLoadError;
    }

    get visibleFields() {
        return this.columns
            .filter((field) => field.fieldAPIName !== 'RecordTypeId')
            .map((field) => ({
                ...field,
                key: field.fieldAPIName,
                isDisabled:
                    field.isValidationField ||
                    field.fieldAPIName === 'Name' ||
                    Boolean(field.disable)
            }));
    }

    get hasProspectSubsidiaryToggle() {
        return this.prospectGroupRecordTypeId != null && this.recordTypeId === this.prospectGroupRecordTypeId;
    }

    get showMatrixCheckbox() {
        return !this.hasProspectSubsidiaryToggle;
    }

    get showLookup() {
        return this.isMobile && Boolean(this.lookupConfig);
    }

    get hasLookupSelection() {
        return this.selectedLookupRecord && this.selectedLookupRecord.Id;
    }

    async loadFormContext() {
        this.isLoading = true;
        this.loadError = undefined;

        try {
            // Keep parity with legacy final form: same Apex fieldset source and help text.
            const [fieldSetResponse, helpTextResponse] = await Promise.all([
                getFieldSetFromAccount({ isAdditional: this.isAdditionalRT }),
                getHelpText()
            ]);

            const parsedFieldSet = JSON.parse(fieldSetResponse);
            this.recordTypeId = parsedFieldSet.recordType;
            this.customIdsResponse = parsedFieldSet.customIdsJSON || {};
            this.columns = this.applyInitialValues(parsedFieldSet.wrapperList || []);
            this.helpText = JSON.parse(helpTextResponse);

            // Load lookup configuration for mobile (CAMBIOS MIGRACIÓN A LWC GLOBAL BANKER)
            if (this.isMobile && this.recordTypeId) {
                try {
                    const lookupResponse = await getFieldLookup({ recordTypeID: this.recordTypeId });
                    this.lookupConfig = JSON.parse(lookupResponse);
                } catch (lookupError) {
                    // Lookup is optional, so don't block form loading if it fails
                    console.warn('Lookup load failed, proceeding without it', lookupError);
                }
            }
        } catch (error) {
            this.loadError = this.normalizeError(error);
        } finally {
            this.isLoading = false;
        }
    }

    handleSubsidiaryNameChange(event){
        this._subsidiaryName = event.target.value;
    }
    _subsidiaryName = this.resolveNameValue();
    get subsidiaryName(){
        return this._subsidiaryName || 'test';
    }

    applyInitialValues(wrapperList) {
        let firstScreenData = {};

        if (this.getDataFirstScreen) {
            try {
                firstScreenData = JSON.parse(this.getDataFirstScreen);
            } catch (error) {
                // eslint-disable-next-line no-console
                console.warn('Invalid getDataFirstScreen payload', error);
            }
        }

        return wrapperList.map((field) => {
            const normalizedField = { ...field };

            // Reuse values captured in Aura duplicate-search screen.
            if (Object.prototype.hasOwnProperty.call(firstScreenData, normalizedField.fieldAPIName)) {
                normalizedField.fieldValue = firstScreenData[normalizedField.fieldAPIName];
                normalizedField.disable = firstScreenData[normalizedField.fieldAPIName];
            }

            if (!firstScreenData.Name && normalizedField.fieldAPIName === 'Name' && this.clientName) {
                normalizedField.fieldValue = this.clientName;
                normalizedField.disable = this.clientName;
            }

            if (normalizedField.fieldAPIName === 'DES_Priority__c' && !normalizedField.fieldValue) {
                normalizedField.fieldValue = 'Medium';
            }

            if (normalizedField.fieldAPIName === 'CIB_Commercial_Prospect__c' && !normalizedField.fieldValue) {
                normalizedField.fieldValue = 'CIB';
            }

            return normalizedField;
        });
    }

    async handleSubmit(event) {
        event.preventDefault();
        this.isSaving = true;

        const fields = { ...event.detail.fields };

        if (this.showProspectSubsidiarySection) {
            if(!this.subsidiaryTaxId){
                this.showToast('', 'Tax ID is required', 'error');
                this.isSaving = false;
                return;
            }
            fields['DES_SubSidiaryCM'] = this._subsidiaryCMSelectedValue;
            fields['DES_SubSidiaryTaxId'] = this.subsidiaryTaxId;
            fields['DES_SubSidiaryName'] = this._subsidiaryName;
            this.prospectSubsidiaryFields.forEach((subField) => {
                if (fields[subField.fieldAPIName] === undefined) {
                    fields[subField.fieldAPIName] = subField.fieldValue || null;
                }
            });
            
            // Añadir Tax ID al payload si está presente
           
        }
        
        // Si el checkbox de matriz está marcado, rellenar DES_Main_Parent__c con participant_id__c
        if (this.isMatrix && fields['participant_id__c']) {
            fields['DES_Main_Parent__c'] = fields['participant_id__c'];
        }
        // Eliminada la comprobación y notificación de error de LEI not available, ya que siempre lo forzamos a true

        const accountValidationPayload = this.buildValidationPayload(fields);

        try {
            const rawValidationResponse = await validateNonClienteComponent({
                acc: accountValidationPayload
            });
            const validationResponse = JSON.parse(rawValidationResponse);

            if (validationResponse.status !== 'success') {
                this.showToast('', validationResponse.message, validationResponse.status);
                return;
            }

            const preparedFields = this.applyServerResponseIds(fields, validationResponse);

            // CAMBIOS MIGRACIÓN A LWC GLOBAL BANKER
            // Always go through Apex createNewAccountNew so the Prospect Subsidiary
            // auto-creation logic runs regardless of whether we are on the Account context.
            const lookupFieldAPIName = this.lookupConfig?.lookupField || '';
            const lookupID = this.selectedLookupRecord?.Id || '';

            let createdRecordId;
            try {
                createdRecordId = await createNewAccountNew({
                    accJSON: JSON.stringify(preparedFields),
                    isAdditional: this.isAdditionalRT,
                    fieldAPIName: lookupFieldAPIName,
                    lookupID: lookupID
                });
            } catch (creationError) {
                // Mostrar error específico si falla la creación de la Prospect Subsidiary
                let errorMsg = 'Error creating Prospect Subsidiary. Please review the data or contact your administrator.';
                if (creationError && creationError.body && creationError.body.message) {
                    errorMsg = creationError.body.message;
                } else if (creationError && creationError.message) {
                    errorMsg = creationError.message;
                }
                this.showToast('Error', errorMsg, 'error');
                this.isSaving = false;
                return;
            }

            if (createdRecordId && createdRecordId.length <= 20) {
                this.recordId = createdRecordId;
                this.handleCreateSuccess(createdRecordId, preparedFields.Name);
            } else {
                // Si el resultado no es un ID válido, mostrar el mensaje devuelto por Apex
                let errorMsg = createdRecordId || 'Failed to create the record. Please review the data or contact your administrator.';
                this.showToast('Error', errorMsg, 'error');
            }
        } catch (error) {
            let errorMsg = 'Unexpected error. Please review the data or contact your administrator.';
            if (error && error.body && error.body.message) {
                errorMsg = error.body.message;
            } else if (error && error.message) {
                errorMsg = error.message;
            }
            this.showToast('Error', errorMsg, 'error');
        } finally {
            this.isSaving = false;
        }
    }

    handleSuccess(event) {
        const createdRecordId = event.detail.id;
        this.recordId = createdRecordId;
        this.handleCreateSuccess(createdRecordId, this.resolveNameValue());
    }

    handleCancel() {
        // Manual close must exit the whole flow like the legacy modal close button.
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    handleClose() {
        // Silent close used after successful save to dismiss the wrapper without re-routing away.
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleBack() {
        // Aura wrapper listens to this event and raises NONC_ceEvent('Back component').
        this.dispatchEvent(new CustomEvent('back'));
    }

    detectMobileDevice() {
        // CAMBIOS MIGRACIÓN A LWC GLOBAL BANKER
        // Detect if device is mobile based on viewport width (matches Aura formFactor behavior)
        this.isMobile = window.innerWidth < 768 || /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
    }

    async handleSubsidiaryToggle(event) {
        // CAMBIOS MIGRACIÓN A LWC GLOBAL BANKER
        this.showProspectSubsidiarySection = Boolean(event.detail.checked);
        if (this.showProspectSubsidiarySection) {
            // Siempre recarga los campos y prellena Name con clientName
            await this.loadProspectSubsidiaryFields();
            this.isMatrix = false; // Resetear Matrix al abrir sección
        }
    }

    handleMatrixCheckboxChange(event) {
        this.isMatrix = event.target.checked;
    }

    async loadProspectSubsidiaryFields() {
        this.isLoadingSubsidiaryFields = true;
        try {
            this._subsidiaryName = this.clientName;
            const raw = await getFieldSetProspectSubsidiary();
            const parsed = JSON.parse(raw) || [];
            // Debug: log clientName and parsed fields
            console.debug('[ProspectSubsidiary] clientName at load:', this.clientName);
            this.prospectSubsidiaryFields = parsed.map((field) => {
                let value = field.fieldValue || null;
                // Prefill Priority
                if (field.fieldAPIName === 'DES_Create_ProspectSubsidiary_Priority__c' && !value) {
                    value = 'Medium';
                }
                return {
                    ...field,
                    key: field.fieldAPIName,
                    fieldValue: value
                };
            });
            this.prospectSubsidiaryFieldsLoaded = true;
        } catch (error) {
            this.showToast('', this.normalizeError(error), 'error');
            this.showProspectSubsidiarySection = false;
        } finally {
            this.isLoadingSubsidiaryFields = false;
        }
    }

    handleSubsidiaryFieldChange(event) {
        // Track user edits to subsidiary fields
        const apiName = event.target.fieldName;
        const value = event.target.value;
        this.prospectSubsidiaryFields = this.prospectSubsidiaryFields.map((f) => {
            if (f.fieldAPIName === apiName) {
                return { ...f, fieldValue: value };
            }
            return f;
        });
    }

    handleLookupSelected(event) {
        // CAMBIOS MIGRACIÓN A LWC GLOBAL BANKER
        const selectedRecord = event.detail.record;
        this.selectedLookupRecord = selectedRecord;
    }

    handleLookupCleared() {
        this.selectedLookupRecord = null;
    }

    buildValidationPayload(fields) {
        const payload = this.columns.reduce((accountPayload, field) => {
            accountPayload[field.fieldAPIName] = fields[field.fieldAPIName];
            return accountPayload;
        }, {});
        // Ensure subsidiary fields travel to backend validation/insert.
        this.prospectSubsidiaryFields.forEach((subField) => {
            if (fields[subField.fieldAPIName] !== undefined) {
                payload[subField.fieldAPIName] = fields[subField.fieldAPIName];
            }
        });
        return payload;
    }

    applyServerResponseIds(fields, serverResponse) {
        const normalizedFields = { ...fields };

        Object.entries(serverResponse || {}).forEach(([key, value]) => {
            if (key === 'status' || key === 'message') {
                return;
            }

            if (this.customIdsResponse[key] && value !== null) {
                normalizedFields[this.customIdsResponse[key]] = value;
            }
        });

        return normalizedFields;
    }

    handleCreateSuccess(createdRecordId, accountName) {
        // Toast parity: legacy Create_Non label = 'Account {0} was created.'
        this.showToast(
            '',
            this.labels.createNon.replace('{0}', accountName || 'Non Client'),
            'success'
        );

        // Navega primero, luego cierra el modal tras un pequeño retardo
        this.navigateToCreatedRecord(createdRecordId);
        setTimeout(() => {
            this.handleClose();
        }, 500); // 500ms para asegurar la navegación
    }

    navigateToCreatedRecord(recordId) {
        if (!recordId) {
            return;
        }

        this[NavigationMixin.Navigate](
            {
                type: 'standard__recordPage',
                attributes: {
                    recordId,
                    objectApiName: 'Account',
                    actionName: 'view'
                }
            },
            true
        );
    }

    resolveNameValue() {
        const nameField = this.columns.find((field) => field.fieldAPIName === 'Name');
        return nameField?.fieldValue || this.clientName;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    normalizeError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((item) => item.message).join(', ');
        }

        return error?.body?.message || error?.message || 'Unexpected error';
    }

    _subsidiaryCountryManagement = null;
    get subsidiaryCountryManagement(){
        return this._subsidiaryCountryManagement;
    }
    _subsidiaryCMSelectedValue = null;
    subsidiaryCMhandleChange(event){
        this._subsidiaryCMSelectedValue = event.detail.value;
    }
}
/*CAMBIOS MIGRACIÓN A LWC GLOBAL BANKER*/