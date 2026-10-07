import { LightningElement, wire, api } from 'lwc'
import { CurrentPageReference } from 'lightning/navigation'
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { getPicklistValues } from 'lightning/uiObjectInfoApi'
import { getRecord, updateRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi'
//import validateFeaturesForClosedWon from '@salesforce/apex/DMT_FeaturesController.validateFeaturesForClosedWon';
import validateSemaphoreRulesForStageChange from '@salesforce/apex/DMT_FeaturesController.validateSemaphoreRulesForStageChange';
import STAGENAME_FIELD from '@salesforce/schema/Opportunity.StageName'
import ID_FIELD from '@salesforce/schema/Opportunity.Id'
import RECORDTYPEID_FIELD from '@salesforce/schema/Opportunity.RecordTypeId'
import REASONLOST_FIELD from '@salesforce/schema/Opportunity.DES_Reasons_Lost__c'
const ERROR_TITLE = 'You encountered some errors when trying to save this record'
const ERROR_PERMISSION =
    'Unable to create/update fields: StageName. Please check the security settings of this field and verify that it is read/write for your profile or permission set.'
const SUCCESS_UPDATING = 'Status changed successfully.'
import getOppLockUser from '@salesforce/apex/DMT_Opportunity_Utils.getOppLockUser';
import USER_ID from '@salesforce/user/Id';
import ClosingFlowModal from 'c/hvsc_oppClosingFlow';

import DMT_LABEL_MODAL_UNSAVED_CHANGES_TITLE from '@salesforce/label/c.DMT_Label_Modal_Unsaved_Changes_Title';
import DMT_LABEL_MODAL_UNSAVED_CHANGES_BODY  from '@salesforce/label/c.DMT_Label_Modal_Unsaved_Changes_Body';
import DMT_LABEL_BTN_EXIT_WITHOUT_SAVING     from '@salesforce/label/c.DMT_Label_Btn_Exit_Without_Saving';
import DMT_LABEL_BTN_KEEP_EDITING            from '@salesforce/label/c.DMT_Label_Btn_Keep_Editing';



/** Normaliza cualquier stage Closed Won/Lost a "Closed" */
const normalize = (stage) => stage?.includes('Closed') ? 'Closed' : stage

export default class Dmt_custom_path_opp extends LightningElement {

    @api recordId

    labels = {
    modalUnsavedChangesTitle : DMT_LABEL_MODAL_UNSAVED_CHANGES_TITLE,
    modalUnsavedChangesBody  : DMT_LABEL_MODAL_UNSAVED_CHANGES_BODY,
    btnExitWithoutSaving     : DMT_LABEL_BTN_EXIT_WITHOUT_SAVING,
    btnKeepEditing           : DMT_LABEL_BTN_KEEP_EDITING
};

    /* ── Estado interno ─────────────────────────────────────────────────────── */

    _currentStage       // Stage real guardada en SF (ej: "Closed Won")
    _selectedStage      // Stage seleccionada visualmente (puede ser "Closed")
    _recordTypeId       // RecordTypeId para cargar picklist
    _rawStages = []     // Valores originales del picklist [{value, label}]
    reasonsLostOptions = []    // Valores del picklist de razones perdidas [{value, label}]
    _isEditing = false; // Tracks the current editing state of the Opportunity record
    _showPendingChangesModal = false; // Controls visibility of the pending changes modal
    closedStageSelected = '' // Valor elegido en el select del modal
    reasonsLostSelected = '' // Valor elegido en el select de razones perdidas (si aplica)
    isLoading = false   // Spinner mientras se actualiza
    isClosedLost = false // Flag para saber que es Closed Lost y poder sacar las razones
   
    @api
    set isEditing(value) {
        this._isEditing = value;
    }

    get isEditing() {
        return this._isEditing;
    }

    get showPendingChangesModal() {
        return this._showPendingChangesModal;
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference && !this.recordId) {
            this.recordId =
                currentPageReference.state?.recordId ||
                currentPageReference.state?.c__recordId ||
                currentPageReference.attributes?.recordId
        }
    }

    /* ── Wire: datos del registro ────────────────────────────────────────────── */

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [STAGENAME_FIELD, RECORDTYPEID_FIELD]
    })
    record({ data }) {
        if (data) {
            this._currentStage = data.fields.StageName.value
            this._selectedStage = normalize(this._currentStage)
            this._recordTypeId = data.fields.RecordTypeId.value
        }
    }

    /* ── Wire: valores del picklist según RecordType ─────────────────────────── */

    @wire(getPicklistValues, {
        recordTypeId: '$_recordTypeId',
        fieldApiName: STAGENAME_FIELD
    })
    picklistValues({ data }) {
        if (data) {
            this._rawStages = data.values.map(o => ({ value: o.value, label: o.label }))
        }
    }

    /* ── Wire: valores del picklist según RecordType ─────────────────────────── */

    @wire(getPicklistValues, {
        recordTypeId: '$_recordTypeId',
        fieldApiName: REASONLOST_FIELD
    })
    picklistValuesReasonLost({ data }) {
        if (data) {
            this.reasonsLostOptions = data.values.map(o => o.value);
            console.log('Reasons Lost Options: ', JSON.stringify(this.reasonsLostOptions));
        }
    }


    /* ── Stages visibles: unifica Closed Won/Lost en un solo "Closed" ──────── */

    get _displayStages() {
        if (!this._rawStages.length) return []
        const seen = new Set()
        return this._rawStages.reduce((acc, s) => {
            const key = normalize(s.value)
            if (!seen.has(key)) {
                seen.add(key)
                acc.push({ value: key, label: key })
            }
            return acc
        }, [])
    }

    /* ── Lista de items para el template (clases SLDS según estado) ────────── */

    get stageItems() {
        const stages = this._displayStages
        if (!stages.length || !this._currentStage) return []

        const current = normalize(this._currentStage)
        const selected = this._selectedStage
        const isWon = this._currentStage === 'Closed Won'
        const isLost = this._currentStage === 'Closed Lost'
        const isClosed = isWon || isLost
        const currentIdx = stages.findIndex(s => s.value === current)

        return stages.map((stage, idx) => {
            let cssClass = 'slds-path__item'

            // Estado base según SLDS
            if (stage.value === 'Closed' && isClosed) {
                cssClass += isWon ? ' slds-is-won slds-is-current' : ' slds-is-lost slds-is-current'
            } else if (stage.value === 'Closed') {
                cssClass += ' slds-is-incomplete'
            } else if (isClosed) {
                cssClass += isWon ? ' slds-is-complete' : ' slds-is-incomplete'
            } else if (stage.value === current) {
                cssClass += ' slds-is-current'
            } else if (currentIdx !== -1 && idx < currentIdx) {
                cssClass += ' slds-is-complete'
            } else {
                cssClass += ' slds-is-incomplete'
            }

            // Stage visualmente seleccionado
            if (stage.value === selected) {
                cssClass += ' slds-is-active'
            }

            return {
                ...stage,
                cssClass,
                isSelected: stage.value === selected ? 'true' : 'false',
                tabindex: stage.value === selected ? '0' : '-1',
            }
        })
    }

    /* ── Getters para el template ─────────────────────────────────────────── */

    get isCurrentSelected() {
        return this._selectedStage === normalize(this._currentStage)
    }

    get isClosed() {
        return this._currentStage?.includes('Closed') ?? false
    }

    /** Texto del botón según SLDS */
    get actionButtonLabel() {
        if (this.isLoading) return 'Saving...'
        if (this._selectedStage === 'Closed') return 'Change Closed State'
        if (this.isClosed && this._selectedStage !== 'Closed') return 'Mark as Current Stage'
        if (this.isCurrentSelected) return 'Mark Status as Complete'
        return 'Mark as Current Stage'
    }

    /** Opciones del select en el modal (valores reales: Closed Won, Closed Lost) */
    get closedStageOptions() {
        return this._rawStages.filter(s => s.value.includes('Closed')).map(s => s.value)
    }

    
    get isSaveDisabled() {
        return !this.closedStageSelected
    }

    /** Siguiente stage lineal (excluyendo Closed) */
    get nextStage() {
        const linear = this._displayStages.filter(s => s.value !== 'Closed')
        const idx = linear.findIndex(s => s.value === this._currentStage)
        return (idx !== -1 && idx < linear.length - 1) ? linear[idx + 1].value : null
    }

    /* ── Handlers ─────────────────────────────────────────────────────────── */

    handleStageClick(event) {
        event.preventDefault()
        this._selectedStage = event.currentTarget.dataset.value
    }

async handleMarkAsCurrent() {
    // Si hay cambios sin guardar → mostrar modal y salir
    if (this._isEditing) {
        this._showPendingChangesModal = true;
        return;
    }
    // Verifica lock antes de continuar
    const isBlocked = await this.isEditingRecord();
    if (isBlocked) {
        // Ya muestra el toast adentro
        return;
    }
    await this.executeMarkAsCurrent();
}

async isEditingRecord() {
    try {
        const opp = await getOppLockUser({ oppId: this.recordId });
        const lockedById = opp?.DMT_Opp_User_Lock__c;
        const lockedBy   = opp?.DMT_Opp_User_Lock__r?.Name;

        if (lockedById && lockedById !== USER_ID) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Record Locked',
                message: `This record is currently being edited by ${lockedBy}. You cannot make any changes at this time.`,
                variant: 'warning',
                mode: 'dismissable'
            }));
            return true; // Está bloqueado por otro
        }
        return false; // No bloqueado, o bloqueado por ti mismo
    } catch (error) {
        // Opcional: puedes mostrar un mensaje aquí si hay error en Apex
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: error?.body?.message || 'Error al verificar el bloqueo.',
            variant: 'error',
            mode: 'dismissable'
        }));
        return true; // Por seguridad, asume bloqueado si hay error
    }
}


    async executeMarkAsCurrent() {
       // Stage "Closed" seleccionado → siempre modal
        if (this._selectedStage === 'Closed') {
            this.closedStageSelected = ''
            ClosingFlowModal.open({
                size: 'small',
                recordId: this.recordId
            });
            return
        }

        // Opp cerrada pero seleccionó un stage no-closed → volver a ese stage
        if (this.isClosed) {
            const isValid = await this.validateSemaphoreForStage(this._selectedStage)
            if (!isValid) return
            this.updateStatus(this._selectedStage)
            return
        }

        // Current seleccionado → avanzar al siguiente
        if (this.isCurrentSelected) {
            const next = this.nextStage
            if (!next) {
                // Último stage lineal → abrir modal de Closed
                this.closedStageSelected = ''
                ClosingFlowModal.open({
                    size: 'small',
                    recordId: this.recordId
                });
                return
            }
            const isValid = await this.validateSemaphoreForStage(next)
            if (!isValid) return
            this.updateStatus(next)
            return
        }

        const isValid = await this.validateSemaphoreForStage(this._selectedStage)
        if (!isValid) return
        this.updateStatus(this._selectedStage)
    }

    handleClosedStageChange(event) {
        this.closedStageSelected = event.target.value
        this.isClosedLost = this.closedStageSelected === 'Closed Lost'
    }
     handleReasonsLostChange(event) {
        this.reasonsLostSelected = event.target.value
    }

    /**
     * Valida las reglas de semáforo (Capability + Workflow, AND/OR) para el stage destino.
     */
    async validateSemaphoreForStage(targetStage) {
        try {
            const result = await validateSemaphoreRulesForStageChange({
                opportunityId: this.recordId,
                targetStatus: targetStage
            })

            if (!result.isValid && result.incompleteFeatures?.length > 0) {
                const featureNames = result.incompleteFeatures.join(', ')
                const featureCount = result.incompleteFeatures.length
                const messageText = featureCount === 1 
                    ? `Opportunity cannot advance to ${targetStage} because the feature ${featureNames} has been rejected.`
                    : `Opportunity cannot advance to ${targetStage} because the features ${featureNames} have been rejected.`
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: messageText,
                    variant: 'error',
                    mode: 'dismissable'
                }))
                /*this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: `Opportunity cannot advance to ${targetStage} because the following features do not meet the required semaphore conditions: ${featureNames}.`,
                    variant: 'error',
                    mode: 'dismissable'
                }))*/
                return false
            }

            return true
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Validation Error',
                message: error?.body?.message || 'Error validating semaphore rules.',
                variant: 'error',
                mode: 'dismissable'
            }))
            return false
        }
    }
     /*async validateClosedWonRequirements() {
        try {
            const result = await validateFeaturesForClosedWon({ opportunityId: this.recordId })

            if (!result.isValid && result.incompleteFeatures && result.incompleteFeatures.length > 0) {
                const featureNames = result.incompleteFeatures.map(feature => feature.name).join(', ')
                const featureCount = result.incompleteFeatures.length
                const messageText = featureCount === 1 
                    ? `Opportunity cannot be closed because feature ${featureNames} has been rejected.`
                    : `Opportunity cannot be closed because features ${featureNames} have been rejected.`
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: messageText,
                    variant: 'error',
                    mode: 'dismissable'
                }))
                return { isValid: false }
            }

            return { isValid: true }
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Validation Error',
                message: error?.body?.message || 'Error validating features.',
                variant: 'error',
                mode: 'dismissable'
            }))
            return { isValid: false }
        }
    }*/

        /* ── Handlers del modal "Pending Changes" ─────────────────────────────── */


    handleCloseModal() {
        this._showPendingChangesModal = false
    }

    async handleExitWithoutSaving() {
        // Notifica al padre que el usuario aceptó salir sin guardar
        await this.dispatchEvent(new CustomEvent('reloadeditmode', {
            bubbles: true,
            composed: true
        }))
        this._showPendingChangesModal = false
        await this.executeMarkAsCurrent();

    }

    /* ── Actualización en Salesforce ──────────────────────────────────────── */

    updateStatus(newStatus) {
        this.isLoading = true
        const fields = {
            [ID_FIELD.fieldApiName]: this.recordId,
            [STAGENAME_FIELD.fieldApiName]: newStatus,
            [REASONLOST_FIELD.fieldApiName]: this.reasonsLostSelected,
        }

        updateRecord({ fields })
            .then(() => {
                this._currentStage = newStatus
                this._selectedStage = normalize(newStatus)
                notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
                this.isLoading = false
                this.dispatchEvent(new ShowToastEvent({
                    title: '', message: SUCCESS_UPDATING, variant: 'success'
                }))
            })
            .catch(error => {
                this.isLoading = false
                let msg
                if (error.status === 403) {
                    msg = ERROR_PERMISSION
                } else {
                    // Validation Rules → body.output.errors[0].message
                    const outputError = error?.body?.output?.errors?.[0]?.message
                    // Field-level errors (e.g. StageName) → body.output.fieldErrors.*[0].message
                    const fieldErrors = error?.body?.output?.fieldErrors
                    const fieldError = fieldErrors
                        ? Object.values(fieldErrors).flat()?.[0]?.message
                        : undefined
                    // Generic body message
                    const bodyMessage = error?.body?.message
                    msg = outputError || fieldError || bodyMessage || JSON.stringify(error?.body) || 'Unknown error'
                }
                console.error('updateRecord error', JSON.stringify(error))
                this.dispatchEvent(new ShowToastEvent({
                    title: ERROR_TITLE, message: msg, variant: 'error'
                }))
            })
    }
}