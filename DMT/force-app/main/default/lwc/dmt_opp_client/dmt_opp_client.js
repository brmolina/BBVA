import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import DMT_OPP_CLIENT_OBJECT from '@salesforce/schema/DMT_Opportunity_Client__c';
import DMT_SECTOR_HEAD from '@salesforce/schema/DMT_Opportunity_Client__c.DMT_Sector_Head__c';
import { clientFields } from './dmt_opp_client_fields.js';
import getOpportunityClientContext from '@salesforce/apex/DMT_OpportunityClientController.getOpportunityClientContext';
import getAllTaxonomyCatalogValues from '@salesforce/apex/DMT_CatalogHelper.getAllTaxonomyCatalogValues';
import saveOpportunityClients from '@salesforce/apex/DMT_HPG_MainTableCustomController.saveOpportunityClients';
import updateMainHolderOnAssociation from '@salesforce/apex/DMT_HPG_MainTableCustomController.updateMainHolderOnAssociation';
import updateMainHolderApprovalData from '@salesforce/apex/DMT_HPG_MainTableCustomController.updateMainHolderApprovalData';
import getMainHolderData from '@salesforce/apex/DMT_OpportunityClientController.getMainHolderData';
import saveClientFormData from '@salesforce/apex/DMT_OpportunityClientController.saveClientFormData';

const EDITABLE_STAGES = new Set(['Draft', 'Ready to close']);
// Default isReadOnly per field — used to restore state when editing is re-enabled
const DEFAULT_READONLY = new Map(clientFields.map(f => [f.id, f.isReadOnly]));
// Counterpart values that show the Fin Inst dependent fields
const FIN_INST_VALUES = new Set(['Fin Inst-B', 'Fin Inst-I', 'Fin Inst']);
// Fields cleared when their visibility condition turns false
const FIN_INST_DEPENDENT_FIELDS = ['SCRA__c', 'AVC_Check__c', 'European_Bank_Check__c'];

export default class Dmt_opp_client extends LightningElement {
    // ─── Public API ───────────────────────────────────────────────────────────
    @api recordId;

    _stageRecord;
    @api
    get stageRecord() {
        return this._stageRecord;
    }
    set stageRecord(value) {
        this._stageRecord = value;
        this._applyReadOnlyRules();
    }

    _canEdit = true;
    @api
    get canEdit() {
        return this._canEdit;
    }
    set canEdit(value) {
        this._canEdit = !!value;
        if (!this._canEdit && this.isEditMode) {
            this._exitEditMode();
        }
        this._applyReadOnlyRules();
    }

    priorRows = [];

    // ─── State ────────────────────────────────────────────────────────────────
    isEditMode = false;
    isLoading = false;
    hasError = false;
    errorMessage = '';
    hasTableError = false;
    isSubsidiary = false;
    opportunity = '';
    customerHPG = '';
    searchDate = '';

    _previousMainBorrower = null;
    _currentMainBorrower = null;
    _currentMainBorrowerRecordId = null;
    _currentSelectedClients = [];

    @track fields = [...clientFields];
    _snapshot = null;
    _options = {};

    // ─── Wire ───────────────────────────────────────────────────────────────
    @wire(getOpportunityClientContext, { opportunityId: '$recordId' })
    wiredClientContext({ data, error }) {
        if (data) {
            // HPG service errors are silent at form level — the form still renders
            // with current saved values. The table is hidden since HPG data is unavailable.
            // Authoritative: the flag follows the real service state, so when HPG
            // recovers on a later (re)load the banner clears on its own, and while
            // it is still down it persists across Save / Cancel.
            this.hasTableError = !!data.serviceError;

            const recordData = data.recordData || {};
            this.fields = this.fields.map(f => {
                const entry = recordData[f.id];
                if (!entry) return f;
                const updated = { ...f, value: entry.currentValue ?? f.value };
                if (entry.originalValue != null) {
                    updated.originalValue = entry.originalValue;
                    updated.overridable = true;
                }
                return updated;
            });

            this.isSubsidiary = data.isSubsidiary || false;
            this.opportunity = data.opportunity || null;
            this.customerHPG = data.hpgData?.CustomerHPG || null;
            this.searchDate = data.searchDate || null;
            this.priorRows = Array.isArray(data.priorRows) ? data.priorRows : [];

            // Apply visibility rules now that isSubsidiary is known and values are set.
            this.fields = this._applyVisibilityRules(this.fields);

            if (data.mainHolder) {
                this._previousMainBorrower = data.mainHolder.Alpha_Code_Client__c || null;
                this._currentMainBorrower = this._previousMainBorrower;
                this._currentMainBorrowerRecordId = data.mainHolder.Id || null;
            }

            // Seed the "current selection" baseline from prior rows so the first
            // snapshot on entering edit mode is accurate before the child fires any
            // selection event.
            this._currentSelectedClients = this.priorRows.map(r => ({ ...r }));
        } else if (error) {
            // Log only — the form renders with empty values regardless.
            console.error('[dmt_opp_client][load]', this._extractErrorMessage(error), error);
        }
    }

    @wire(getObjectInfo, { objectApiName: DMT_OPP_CLIENT_OBJECT })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: DMT_SECTOR_HEAD
    })
    wiredSectorHead({ data, error }) {
        if (data) {
            this._options = {
                ...this._options,
                DMT_Sector_Head__c: data.values.map(({ label, value }) => ({ label, value }))
            };
            this._applyOptionsToFields();
        } else if (error) {
            console.error('[dmt_opp_client] getPicklistValues DMT_Sector_Head__c error:', error);
        }
    }

    @wire(getAllTaxonomyCatalogValues)
    wiredCatalogs({ data, error }) {
        if (data) {
            this._options = {
                g_upd_lmscl_internal_ratg_type__c: data['C204'] || [],
                External_Rating__c: this._withEmptyOption(data['C009']),
                DMT_External_Rating_SP__c: data['C519'] || [],
                DMT_External_Rating_Moodys__c: data['C090'] || [],
                DMT_External_Rating_Fitch__c: data['C087'] || [],
                Counterpart__c: data['D971'] || [],
                SCRA__c: data['C204'] || [],
                DMT_Sector__c: data['C162'] || [],
                DMT_Subsector__c: data['C164'] || [],
                DMT_Activity__c: data['C039'] || []
            };
            this._applyOptionsToFields();
        } else if (error) {
            console.error('[dmt_opp_client] getAllTaxonomyCatalogValues error:', error);
        }
    }

    // ─── Computed ───────────────────────────────────────────────────────────
    get disableEdit() {
        return !this._canEdit || !EDITABLE_STAGES.has(this.stageRecord);
    }

    get hasIdentityData() {
        return this.isSubsidiary && !!this.customerHPG && !!this.opportunity;
    }

    get formContainerClass() {
        return this.isEditMode ? 'slds-is-relative form-container--edit-mode' : 'slds-is-relative';
    }

    get tableErrorMessage() {
        return this.isSubsidiary
            ? 'The client data service is temporarily unavailable. Risk field values cannot be displayed at this time. Please try again in a few minutes.'
            : 'The client data service is temporarily unavailable. The client table and risk fields cannot be displayed at this time. Please try again in a few minutes.';
    }

    get customerName() {
        return this.customerHPG?.customerName || '';
    }

    get opportunityAccountId() {
        return this.opportunity?.AccountId || '';
    }

    // ─── Edit mode ──────────────────────────────────────────────────────────
    handleEditModeChange(event) {
        if (!event.detail?.isEditMode || this.disableEdit) return;
        this._enterEditMode();
    }

    // Called when child dispatches 'editmode' (user selected a row or toggled main borrower)
    handleEditMode() {
        if (this.disableEdit || this.isEditMode) return;
        this._enterEditMode();
    }

    _enterEditMode() {
        const childCmp = this.refs.selectClients;
        const selectionData = childCmp
            ? childCmp.getSelectionData()
            : { selectedClients: this._currentSelectedClients, mainHolder: this._currentMainBorrower };
        this._snapshot = {
            fields: this.fields.map(f => ({ ...f })),
            selectedClients: (selectionData.selectedClients || []).map(c => ({ ...c })),
            mainHolder: selectionData.mainHolder || this._previousMainBorrower || null
        };
        this.isEditMode = true;
    }

    // ─── Selection events from child ──────────────────────────────────────────
    // NOTE: _currentSelectedClients is intentionally NOT updated here.
    // It represents the last *saved* state and is the baseline for change
    // detection in handleSave. Updating it here would make selectedClientsChanged
    // always false, causing saveOpportunityClients to be skipped on save.
    // The live selection is always read fresh from childCmp.getSelectionData().
    handleSelection(_event) {}

    async handleMainHolder(event) {
        const newMainBorrower = event.detail?.mainHolder || null;
        const previousValidMainBorrower = this._currentMainBorrower;

        if (!newMainBorrower || !this.recordId) {
            this._currentMainBorrower = newMainBorrower;
            return;
        }
        if (newMainBorrower === previousValidMainBorrower) return;

        this._currentMainBorrower = newMainBorrower;
        this.isLoading = true;
        try {
            const data = await getMainHolderData({ opportunityId: this.recordId, alphaCode: newMainBorrower });

            // Track the SF record Id for the save operation.
            if (data.mainBorrower?.Id) {
                this._currentMainBorrowerRecordId = data.mainBorrower.Id;
            }

            const recordData = data.recordData || {};
            // HPG service errors are silent at form level — form still renders.
            this.fields = this.fields.map(f => {
                const entry = recordData[f.id];
                if (!entry) return f;
                const updated = { ...f, value: entry.currentValue ?? f.value };
                delete updated.originalValue;
                if (entry.originalValue != null) {
                    updated.originalValue = entry.originalValue;
                    updated.overridable = true;
                }
                return updated;
            });

            // Re-apply visibility with the new values.
            this.fields = this._applyVisibilityRules(this.fields);
        } catch (error) {
            // Revert to the previous valid main borrower on any Apex exception.
            this._currentMainBorrower = previousValidMainBorrower;
            const childCmp = this.refs.selectClients;
            if (childCmp) {
                const current = childCmp.getSelectionData();
                childCmp.restoreSelection({
                    selectedClients: current.selectedClients,
                    mainHolder: previousValidMainBorrower
                });
            }
            this._showErrorToast(this._classifyUserMessage('load', this._extractErrorMessage(error)));
            console.error('[dmt_opp_client][mainBorrower]', error);
        } finally {
            this.isLoading = false;
        }
    }

    // ─── Field change ─────────────────────────────────────────────────────────
    async handleFieldChange(event) {
        const { fieldId, value } = event.detail;
        const idx = this.fields.findIndex(f => f.id === fieldId);
        if (idx === -1) return;

        const previousValue = this.fields[idx].value; // capture before mutation
        let updated = this.fields.slice();
        updated[idx] = { ...this.fields[idx], value };

        // Re-apply visibility after the value change so dependent fields
        // show/hide immediately. Also clear values of fields being hidden.
        const VISIBILITY_TRIGGERS = new Set(['Counterpart__c', 'DMT_Sector__c', 'DMT_Subsector__c']);
        if (VISIBILITY_TRIGGERS.has(fieldId)) {
            updated = this._applyVisibilityRules(updated);
        }
        this.fields = updated;

        // ── Quick-save: field changed outside edit mode ────────────────────────
        // The form renderer can emit field changes without entering edit mode
        // (e.g. inline picklist). In that case we auto-save but ask for
        // confirmation first so the user is aware of what is happening.
        if (!this.isEditMode) {
            const confirmed = await LightningConfirm.open({
                label: 'Save changes?',
                message: 'This field was changed inline and will be saved immediately to the record. Do you want to continue?',
                theme: 'warning'
            });
            if (confirmed) {
                try {
                    this.isLoading = true;
                    await this._saveFormFields();
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success',
                        message: 'Record saved successfully.',
                        variant: 'success'
                    }));
                } catch (error) {
                    this._handleApexError('save', error);
                    // Revert field on failure.
                    this.fields = this.fields.map((f, i) =>
                        i === idx ? { ...f, value: previousValue } : f
                    );
                } finally {
                    this.isLoading = false;
                }
            } else {
                // User cancelled — revert to the value before the change.
                this.fields = this.fields.map((f, i) =>
                    i === idx ? { ...f, value: previousValue } : f
                );
            }
        }
    }

    // ─── Load errors from child (table data fetch) ────────────────────────────
    handleLoadError(event) {
        // If the service error banner is already visible (hasTableError was set by
        // wiredClientContext via serviceError), the child's load failure is a
        // consequence of the same outage — suppress the duplicate inline error.
        const alreadyKnown = this.hasTableError;
        this.hasTableError = true;
        if (!alreadyKnown) {
            this._handleApexError('load', event.detail?.error || event.detail?.message);
        }
    }

    // ─── Save ───────────────────────────────────────────────────────────────
    async handleSave() {
        this.isLoading = true;
        this.hasError = false;
        this.errorMessage = '';
        const childCmp = this.refs.selectClients;

        try {
            const selectionData = childCmp
                ? childCmp.getSelectionData()
                : { selectedClients: [], mainHolder: null };
            const { selectedClients, mainHolder } = selectionData;

            if (!mainHolder && !this.isSubsidiary) {
                this._showErrorToast('You must select at least one Main Borrower before saving.');
                return;
            }

            // ── Save form fields (atomic: DMT_Opportunity_Client__c + Passport__c + Opportunity)
            await this._saveFormFields();

            // ── Main borrower association — only when something changed ───────────
            const mainBorrowerChanged = mainHolder !== this._previousMainBorrower;
            const selectedClientsChanged =
                JSON.stringify(selectedClients) !== JSON.stringify(this._currentSelectedClients);

            if (mainBorrowerChanged || selectedClientsChanged) {
                const isNewRecord = !this._previousMainBorrower;

                // New record: association must exist before saving clients
                if (isNewRecord) {
                    await updateMainHolderOnAssociation({ opportunityId: this.recordId, alphaCode: mainHolder });
                }

                await saveOpportunityClients({
                    selectedClients: JSON.parse(JSON.stringify(selectedClients)),
                    opportunityId: this.recordId
                });

                // Existing record with changed main borrower: update association after clients
                if (!isNewRecord && mainBorrowerChanged) {
                    await updateMainHolderOnAssociation({ opportunityId: this.recordId, alphaCode: mainHolder });
                }

                if (mainBorrowerChanged && this._previousMainBorrower) {
                    await updateMainHolderApprovalData({
                        opportunityId: this.recordId,
                        mainHolderPrevious: this._previousMainBorrower,
                        mainHolderNew: mainHolder
                    });
                }

                this._previousMainBorrower = mainHolder;
                this._currentSelectedClients = selectedClients;
                this._currentMainBorrower = mainHolder;
            }

            this._exitEditMode();
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Record saved successfully.',
                variant: 'success'
            }));
        } catch (error) {
            this._handleApexError('save', error);
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * @description Saves only the form fields atomically (DMT_Opportunity_Client__c,
     * Passport__c, Opportunity). Used both by handleSave (full save) and the
     * quick-save path (field change outside edit mode).
     * Throws on failure so the caller can handle the error.
     */
    async _saveFormFields() {
        const dmtClientId = this._currentMainBorrowerRecordId;
        if (!dmtClientId) {
            throw new Error('Cannot save: main borrower record not found.');
        }
        const fieldValues = Object.fromEntries(
            this.fields
                .filter(f => !f.isHidden)
                .map(f => [f.id, f.value ?? null])
        );
        await saveClientFormData({
            opportunityId: this.recordId,
            dmtClientId,
            stageName: this.stageRecord,
            fieldValues
        });
    }

    // ─── Cancel ─────────────────────────────────────────────────────────────
    handleCancel() {
        if (this._snapshot) {
            this.fields = this._snapshot.fields;
            const childCmp = this.refs.selectClients;
            if (childCmp) {
                childCmp.restoreSelection({
                    selectedClients: this._snapshot.selectedClients,
                    mainHolder: this._snapshot.mainHolder
                });
            }
            this._currentSelectedClients = this._snapshot.selectedClients;
            this._currentMainBorrower = this._snapshot.mainHolder;
        }
        this._exitEditMode();
    }

    // ─── Private ──────────────────────────────────────────────────────────────
    _applyOptionsToFields() {
        this.fields = this.fields.map(f => {
            if (f.type !== 'picklist') return f;
            const options = this._options[f.id];
            return options ? { ...f, options } : f;
        });
    }

    /**
     * @description Applies all field-level visibility rules to a fields array.
     * Returns a NEW array — never mutates in place.
     * When a field transitions visible → hidden its value is cleared automatically.
     *
     * Rules:
     *  1. currentRatingToolDate        → visible only when isSubsidiary
     *  2. SCRA__c, AVC_Check__c,
     *     European_Bank_Check__c       → visible when Counterpart__c ∈ FIN_INST_VALUES
     *  3. DMT_Subsector__c             → visible when DMT_Sector__c is not blank
     *  4. DMT_Activity__c              → visible when DMT_Sector__c AND DMT_Subsector__c are not blank
     */
    _applyVisibilityRules(fields) {
        const valueOf = id => (fields.find(f => f.id === id)?.value) || '';

        const showFinInst = FIN_INST_VALUES.has(valueOf('Counterpart__c'));
        const showSubsector = valueOf('DMT_Sector__c') !== '';
        const showActivity = valueOf('DMT_Sector__c') !== '' && valueOf('DMT_Subsector__c') !== '';

        // Map each field id to whether it should be visible
        const visibilityMap = {
            currentRatingToolDate: this.isSubsidiary,
            ...Object.fromEntries(FIN_INST_DEPENDENT_FIELDS.map(id => [id, showFinInst])),
            DMT_Subsector__c: showSubsector,
            DMT_Activity__c: showActivity
        };

        return fields.map(f => {
            if (!(f.id in visibilityMap)) return f;
            const shouldBeHidden = !visibilityMap[f.id];
            const clearing = shouldBeHidden && !f.isHidden; // transitioning visible → hidden
            const newValue = clearing ? (f.type === 'checkbox' ? false : '') : f.value;
            if (shouldBeHidden === f.isHidden && newValue === f.value) return f;
            return { ...f, isHidden: shouldBeHidden, value: newValue };
        });
    }

    _withEmptyOption(options, label = '', value = '') {
        return [{ label, value }, ...(options || [])];
    }

    _applyReadOnlyRules() {
        const locked = this.disableEdit;
        this.fields = this.fields.map(f => {
            const defaultReadOnly = DEFAULT_READONLY.get(f.id) ?? false;
            const newReadOnly = locked ? true : defaultReadOnly;
            return newReadOnly === f.isReadOnly ? f : { ...f, isReadOnly: newReadOnly };
        });
    }

    _exitEditMode() {
        this._snapshot = null;
        this.isEditMode = false;
        this.hasError = false;
        this.errorMessage = '';
        // NOTE: hasTableError is intentionally NOT cleared here. The HPG/service
        // error must persist across Save and Cancel until a successful (re)load
        // confirms the service is back. It is owned solely by the data-load path
        // (wiredClientContext / handleLoadError).
    }

    _showErrorToast(message, title = 'Error') {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant: 'error', mode: 'dismissable' }));
    }

    // ─── Error handling (centralised for load + save) ─────────────────────────
    _handleApexError(context, error) {
        const rawMessage = this._extractErrorMessage(error);
        console.error(`[dmt_opp_client][${context}]`, rawMessage, error);
        this.hasError = true;
        this.errorMessage = this._classifyUserMessage(context, rawMessage);
    }

    _classifyUserMessage(context, rawMessage) {
        const lower = String(rawMessage || '').trim().toLowerCase();

        if (lower.includes('customer not found')) {
            return 'The client could not be found in the HPG service. Original values are not available for comparison.';
        }
        if (
            lower.includes('hpg') ||
            lower.includes('global position') ||
            lower.includes('service unavailable') ||
            lower.includes('statuscode') ||
            lower.includes('callout') ||
            lower.includes('read timed out')
        ) {
            return 'The HPG service is currently unavailable. Please try again in a few minutes.';
        }
        if (
            lower.includes('null') ||
            lower.includes('internal server error') ||
            lower.includes('script-thrown exception')
        ) {
            return context === 'save'
                ? 'An internal error occurred while saving your changes. Please try again.'
                : 'An internal error occurred while loading client information. Please try again.';
        }
        return context === 'save'
            ? 'Unable to save your changes. Please review the data and try again.'
            : 'Unable to load client information. Please try again.';
    }

    _extractErrorMessage(error) {
        if (!error) return 'Unknown error.';
        if (typeof error === 'string') return error;
        const body = error.body;
        if (Array.isArray(body) && body.length > 0) {
            return body.map(e => e.message).filter(Boolean).join(' | ');
        }
        if (body?.message) return body.message;
        if (error.message) return error.message;
        return String(error);
    }
}