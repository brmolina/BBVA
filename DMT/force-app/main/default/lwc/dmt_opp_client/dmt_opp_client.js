import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import DMT_OPP_CLIENT_OBJECT from '@salesforce/schema/DMT_Opportunity_Client__c';
import DMT_SECTOR_HEAD from '@salesforce/schema/DMT_Opportunity_Client__c.DMT_Sector_Head__c';
import PRODUCT_AREA_FIELD from '@salesforce/schema/Opportunity.DMT_Product_Area__c';
import { applyNbcMarks } from 'c/dmt_nbc_marks';
import { clientFields } from './dmt_opp_client_fields.js';
import getOpportunityClientContext from '@salesforce/apex/DMT_OpportunityClientController.getOpportunityClientContext';
import getAllTaxonomyCatalogValues from '@salesforce/apex/DMT_CatalogHelper.getAllTaxonomyCatalogValues';
import getMainHolderData from '@salesforce/apex/DMT_OpportunityClientController.getMainHolderData';
import saveMainBorrowerWithClients from '@salesforce/apex/DMT_OpportunityClientController.saveMainBorrowerWithClients';
import saveMainBorrowerFields from '@salesforce/apex/DMT_OpportunityClientController.saveMainBorrowerFields';
import getCasesByOpportunity from '@salesforce/apex/DMT_ModalSaveController.getCasesByOpportunity';


const DEFAULT_READONLY = new Map(clientFields.map(f => [f.id, f.isReadOnly]));
const FIN_INST_VALUES = new Set(['Fin Inst-B', 'Fin Inst-I', 'Fin Inst']);
const FIN_INST_DEPENDENT_FIELDS = ['SCRA__c', 'AVC_Check__c', 'European_Bank_Check__c'];
const DEFAULT_ERROR_MESSAGE = 'An unexpected error occurred. Please contact an administrator.';
const PLACEHOLDER_MESSAGES = new Set([
    'script-thrown exception',
    'an error occurred while trying to update the record. please try again.'
]);
const WIRED_CATALOG_PICKLIST_FIELDS = new Set([
    'g_upd_lmscl_internal_ratg_type__c',
    'External_Rating__c',
    'DMT_External_Rating_SP__c',
    'DMT_External_Rating_Moodys__c',
    'DMT_External_Rating_Fitch__c',
    'Counterpart__c',
    'SCRA__c',
    'DMT_Sector__c',
    'DMT_Subsector__c',
    'DMT_Activity__c'
    //'DMT_CAMN__c'
]);
const INVALID_CATALOG_VALUE_MESSAGE = 'The service value is inconsistent. It is not a valid option';

export default class Dmt_opp_client extends LightningElement {
    // ─── Public API ───────────────────────────────────────────────────────────
    _recordId;
    @api get recordId() { return this._recordId; }
    set recordId(v) {
        this._recordId = v;
        if (v) this._loadClientContext();
    }

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

    // Fields required by the "Passport" service that are missing on this tab, as an array of
    // { apiName, label } (per DMT_FieldsRequiredParser.parse()). Used to highlight them in the form.
    _missingPassportFields = [];
    @api
    get missingPassportFields() {
        return this._missingPassportFields;
    }
    set missingPassportFields(value) {
        this._missingPassportFields = value || [];
        if (this._dataLoaded) {
            this._applyMissingPassportHighlight();
        }
    }

    // True when the user selected a single field from dmt_missingFieldsPopover (as opposed to
    // "Review all", which sends every pending field across every tab). Only in that case do we
    // warn about a requested field that doesn't exist on this tab. Needs its own setter (instead
    // of a plain @api field) because the template sets `missing-passport-fields` before
    // `is-single-field-warning`: without this, _applyMissingPassportHighlight() would run with the
    // previous event's value, making the toasts appear one event late.
    _isSingleFieldWarning = false;
    @api
    get isSingleFieldWarning() {
        return this._isSingleFieldWarning;
    }
    set isSingleFieldWarning(value) {
        this._isSingleFieldWarning = value;
        if (this._dataLoaded) {
            this._applyMissingPassportHighlight();
        }
    }

    priorRows = [];

    // ─── State ────────────────────────────────────────────────────────────────
    isEditMode = false;
    isLoading = true;
    hasError = false;
    errorMessage = '';
    hasTableError = false;
    isSubsidiary = false;
    opportunity = '';
    customerHPG = '';
    defaultFilterClients;
    serviceErrorMessage = null;

    _previousMainBorrower = null;
    _currentMainBorrower = null;
    _currentMainBorrowerRecordId = null;
    _currentSelectedClients = [];
    _dataLoaded = false;
    // Dedupe key for the last "field not found" toast shown, so the same unmatched
    // Passport field(s) don't re-trigger the toast on every re-render/save.
    _lastUnmatchedPassportFieldsKey = null;
    // Dedupe key for the last "field already filled in" toast shown (single-field selection only).
    _lastAlreadyFilledFieldKey = null;

    @track fields = [...clientFields];
    _snapshot = null;
    _options = {};

    // NBC Local/Global marks: driven by each field's own `nbcScope` in dmt_opp_client_fields.js.
    // No field currently sets nbcScope on this tab — this wiring is dormant until one does.
    isGtb = false;

    // ─── Wire ───────────────────────────────────────────────────────────────

    @wire(getRecord, { recordId: '$recordId', fields: [PRODUCT_AREA_FIELD] })
    wiredProductArea({ data }) {
        if (!data) return;
        const productArea = data.fields.DMT_Product_Area__c?.value;
        const isGtb = productArea === 'GTB';
        if (isGtb === this.isGtb) return;
        this.isGtb = isGtb;
        this.fields = applyNbcMarks(this.fields, isGtb);
    }

    async _loadClientContext() {
        if (!this._recordId) return;
        try {
            const data = await getOpportunityClientContext({ opportunityId: this._recordId });
            // HPG service errors are silent at form level — the form still renders
            // with current saved values. The table is hidden since HPG data is unavailable.
            // Authoritative: the flag follows the real service state, so when HPG
            // recovers on a later (re)load the banner clears on its own, and while
            // it is still down it persists across Save / Cancel.
            this.hasTableError = !!data.serviceError;
            this.serviceErrorMessage = data.serviceErrorMessage || null;

            const recordData = data.recordData || {};
            this.fields = this.fields.map(f => {
                const entry = recordData[f.id];
                if (!entry) return f;
                const rawValue = entry.currentValue ?? f.value;
                const updated = { ...f, value: rawValue != null ? rawValue : (f.type === 'checkbox' ? false : '') };
                if (entry.originalValue != null) {

                    updated.originalValue = entry.originalValue;
                    updated.overridable = true;
                }
                return this._flagInvalidCatalogValue(updated);
            });

            this.isSubsidiary = data.isSubsidiary || false;
            this.opportunity = data.opportunity || null;
            this.defaultFilterClients =
                this.opportunity?.Account?.RecordType?.DeveloperName === 'Prospect_Group' ? 'Y/N' : 'Y';
            this.customerHPG = data.hpgData || null;
            this.priorRows = Array.isArray(data.priorRows) ? data.priorRows : [];

            // Apply visibility rules now that isSubsidiary is known and values are set.
            this.fields = this._applyVisibilityRules(this.fields);
            this.fields = applyNbcMarks(this.fields, this.isGtb);

            if (data.mainHolder) {
                this._previousMainBorrower = data.mainHolder.Alpha_Code_Client__c || null;
                this._currentMainBorrower = this._previousMainBorrower;
                this._currentMainBorrowerRecordId = data.mainHolder.Id || null;
            }

            // Seed the "current selection" baseline from prior rows so the first
            // snapshot on entering edit mode is accurate before the child fires any
            // selection event.
            this._currentSelectedClients = this.priorRows.map(r => ({ ...r }));
            this.isLoading = false;
            this._dataLoaded = true;
            this._applyMissingPassportHighlight();
        } catch (error) {
            // Log only — the form renders with empty values regardless.
            console.error('[dmt_opp_client][load]', this._extractErrorMessage(error), error);
            this.isLoading = false;
            this._dataLoaded = true;
            this._applyMissingPassportHighlight();
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
                DMT_Activity__c: data['C039'] || [],
                DMT_CAMN__c: data['A521'] || [],
            };
            this._applyOptionsToFields();
        } else if (error) {
            console.error('[dmt_opp_client] getAllTaxonomyCatalogValues error:', error);
        }
    }

    // ─── Computed ───────────────────────────────────────────────────────────
    get disableEdit() {
        return !this._canEdit;
    }

    get hasIdentityData() {
        return this.isSubsidiary && !!this.customerHPG && !!this.opportunity;
    }

    get formContainerClass() {
        return this.isEditMode ? 'slds-is-relative form-container--edit-mode' : 'slds-is-relative';
    }

    get tableErrorMessage() {
        if (this.serviceErrorMessage) {
            return this._classifyUserMessage('load', this.serviceErrorMessage);
        }
        return this.isSubsidiary
            ? 'The client data service is temporarily unavailable. Original values are not available at this time. Please try again in a few minutes.'
            : 'The client data service is temporarily unavailable. Original values and the client table are not available at this time. Please try again in a few minutes.';
    }

    get mainHolderAlphaCode() {
        if (!this.isSubsidiary) return null;
        return this.customerHPG?.customerId || this._previousMainBorrower || null;
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
        this.notifyEditMode(true);
    }

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
            const data = await getMainHolderData({
                opportunityId: this.recordId,
                alphaCode: newMainBorrower,
                originalRecordTable: event.detail?.originalRecord || null
            });

            // Track the SF record Id for the save operation.
            if (data.mainBorrower?.Id) {
                this._currentMainBorrowerRecordId = data.mainBorrower.Id;
            }

            const recordData = data.recordData || {};
            // HPG service errors are silent at form level — form still renders.
            this.fields = this.fields.map(f => {
                const entry = recordData[f.id];
                if (!entry) return f;
                const rawValue = entry.currentValue ?? f.value;
                const updated = { ...f, value: rawValue != null ? rawValue : (f.type === 'checkbox' ? false : '') };
                delete updated.originalValue;
                if (entry.originalValue != null) {
                    updated.originalValue = entry.originalValue;
                    updated.overridable = true;
                }
                return this._flagInvalidCatalogValue(updated);
            });

            // Re-apply visibility with the new values.
            this.fields = this._applyVisibilityRules(this.fields);
            this.fields = applyNbcMarks(this.fields, this.isGtb);

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Main borrower updated',
                    message: `Form fields have been refreshed with data from client ${newMainBorrower}.`,
                    variant: 'info'
                })
            );
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

    // ─── Field change ───────────────────────────────────────────────────────────
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
            const confirmed = await this._confirmReadyToCloseModify(true);

            if (confirmed) {
                try {
                    this.isLoading = true;
                    await this._saveFieldsOnly();
                    this.notifyEditMode(false);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Record saved successfully.',
                            variant: 'success'
                        })
                    );
                } catch (error) {
                    this._showErrorToast(this._classifyUserMessage('save', this._extractErrorMessage(error)));
                    // Revert field on failure and re-apply visibility rules.
                    const reverted = this.fields.map((f, i) =>
                        i === idx ? { ...f, value: previousValue } : f
                    );
                    this.fields = this._applyVisibilityRules(reverted);
                } finally {
                    this.isLoading = false;
                }
            } else {
                // User cancelled — revert to the value before the change and re-apply visibility rules.
                const reverted = this.fields.map((f, i) =>
                    i === idx ? { ...f, value: previousValue } : f
                );
                this.fields = this._applyVisibilityRules(reverted);
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

    // ─── Save ─────────────────────────────────────────────────────────────────
    async handleSave() {
        this.isLoading = true;
        this.hasError = false;
        this.errorMessage = '';
        const childCmp = this.refs.selectClients;
        try {
            // ── Cases check when stage is 'Ready to close' ──────────────────────
            if (!await this._confirmReadyToCloseModify()) return;

            const selectionData = childCmp
                ? childCmp.getSelectionData()
                : { selectedClients: [], mainHolder: null };
            const { selectedClients, mainHolder } = selectionData;

            if (!mainHolder && !this.isSubsidiary) {
                this._showErrorToast('You must select at least one Main Borrower before saving.');
                return;
            }

            // ── Required fields validation ──────────────────────────────────
            const missingRequired = this.fields.filter(f =>
                f.isRequired === true &&
                !f.isHidden &&
                (f.value === null || f.value === undefined || f.value === '' ||
                    (typeof f.value === 'boolean' ? false : false))
            );
            if (missingRequired.length > 0) {
                const labels = missingRequired.map(f => f.label).join(', ');
                this.isLoading =  false;
                this.hasError = true;
                this.errorMessage = `The following required fields must be filled in: ${labels}`;
                return;
            }

            // ── Save form fields ─────────────────────────────────────────────
            // Subsidiaries don't manage client selection, so only field values
            // need to be persisted. Full form save (selection + associations) is
            // reserved for non-subsidiary opportunities.
            if (this.isSubsidiary) {
                await this._saveFieldsOnly();
            } else {
                await this._saveFormFields(selectedClients, mainHolder);
                this._previousMainBorrower = mainHolder;
                this._currentSelectedClients = selectedClients;
                this._currentMainBorrower = mainHolder;
            }

            this._applyMissingPassportHighlight();
            this._exitEditMode();
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Record saved successfully.',
                    variant: 'success'
                })
            );
        } catch (error) {
            this._handleApexError('save', error);
            this._showErrorToast(this.errorMessage);
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * @description Quick-save: updates only the form fields on the existing
     * DMT_Opportunity_Client__c of the current main borrower, plus the Opportunity.
     * Does NOT touch client selection, associations, or other related records.
     * Throws on failure so the caller can handle the error.
     */
    async _saveFieldsOnly() {
        const dmtClientId = this._currentMainBorrowerRecordId;
        const fieldValues = Object.fromEntries(
            this.fields.filter(f => !f.isHidden).map(f => [f.id, f.value ?? null])
        );
        await saveMainBorrowerFields({
            opportunityId: this.recordId,
            dmtClientId,
            stageName: this.stageRecord,
            fieldValues
        });
    }

    /**
     * @description Saves the form fields + client selection atomically
     * (DMT_Opportunity_Client__c, Passport__c, Opportunity, associations).
     * Used by handleSave (full edit-mode save).
     * Throws on failure so the caller can handle the error.
     */
    async _saveFormFields(selectedClients, mainHolder) {
        const dmtClientId = this._currentMainBorrowerRecordId;
        const fieldValues = Object.fromEntries(
            this.fields.filter(f => !f.isHidden).map(f => [f.id, f.value ?? null])
        );
        await saveMainBorrowerWithClients({
            opportunityId: this.recordId,
            dmtClientId,
            stageName: this.stageRecord,
            fieldValues,
            selectedClients: selectedClients,
            mainBorrower: mainHolder
        });
    }

    // ─── Ready-to-close guard ─────────────────────────────────────────────────
    /**
     * @description When the stage is 'Ready to close' and there are open cases,
     * shows a confirmation dialog warning the user that cases and tasks will be
     * reopened. Returns true to proceed, false to abort.
     */
    async _confirmReadyToCloseModify(fromInline = false) {
        let hasCases = false;
        if (this.stageRecord === 'Ready to close') {
            const cases = await getCasesByOpportunity({ opportunityId: this.recordId });
            hasCases = !!(cases && cases.length > 0);
        }

        // From handleSave: skip the dialog entirely when there are no open cases.
        if (!fromInline && !hasCases) return true;

        const label = fromInline ? 'Save changes?' : 'Modify Opportunity?';
        const message = fromInline
            ? hasCases
                ? 'This field was changed inline and will be saved immediately to the record.' +
                  ' The Opportunity is in \'Ready to close\' stage: the associated cases and tasks will be reopened.' +
                  '\n\nDo you want to continue?'
                : 'This field was changed inline and will be saved immediately to the record. Do you want to continue?'
            : 'The Opportunity will be modified and the associated cases and tasks will be reopened.' +
              '\n\nDo you want to modify the Opportunity?';

        return LightningConfirm.open({ label, message, theme: 'warning' });
    }

    // ─── Cancel ─────────────────────────────────────────────────────────────────
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

    // ─── Private ──────────────────────────────────────────────────────────────────
    _applyOptionsToFields() {
        this.fields = this.fields.map(f => {
            if (f.type !== 'picklist') return f;
            const options = this._options[f.id];
            const updated = options ? { ...f, options } : f;
            return this._flagInvalidCatalogValue(updated);
        });
    }

    /**
     * @description For fields whose picklist options come from wiredCatalogs, checks
     * whether the field's originalValue (the service/HPG-inferred value) exists among
     * the loaded options. This — not the current/DB value — is what can be inconsistent:
     * when an Opportunity is created the inferred value isn't persisted if it doesn't
     * exist in the catalog, so `field.value` is typically blank/valid while
     * `field.originalValue` still carries the invalid inferred code.
     * If the catalog hasn't loaded yet (no options), or there is no originalValue to
     * check, or it is valid, the field is returned unchanged. Otherwise the
     * inconsistency warning replaces originalValue/overridable and disables the
     * revert action (revertDisabled).
     */
    _flagInvalidCatalogValue(field) {
        if (!WIRED_CATALOG_PICKLIST_FIELDS.has(field.id)) return field;
        if (!field.options || field.options.length === 0) return field;
        if (field.originalValue === null || field.originalValue === undefined || field.originalValue === '') return field;
        const exists = field.options.some(o => o.value === (field.originalValue?.value ? field.originalValue.value : field.originalValue));
        if (exists) return field;
        return {
            ...field,
            originalValue: INVALID_CATALOG_VALUE_MESSAGE,
            overridable: true,
            revertDisabled: true
        };
    }

    /**
     * @description Applies all field-level visibility rules to a fields array.
     * Returns a NEW array — never mutates in place.
     * When a field transitions visible → hidden its value is cleared automatically.
     *
     * Rules:
     *   1. currentRatingToolDate    → visible only when isSubsidiary
     *   2. SCRA__c, AVC_Check__c,
     *      European_Bank_Check__c   → visible when Counterpart__c ∈ FIN_INST_VALUES
     *   3. DMT_Subsector__c         → visible when DMT_Sector__c is not blank
     *   4. DMT_Activity__c          → visible when DMT_Sector__c AND DMT_Subsector__c are not blank
     */
    _applyVisibilityRules(fields) {
        const valueOf = id => fields.find(f => f.id === id)?.value || '';

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

    // Highlights fields present in _missingPassportFields whose value is currently empty, and
    // reports up to the parent (via `passportwarningchange`) whether any are still empty so the
    // tab/More button can show a warning icon. Hidden fields are skipped entirely. Re-evaluates on
    // every call (e.g. after save) so a field that was just filled in, or hidden, stops being
    // highlighted.
    _applyMissingPassportHighlight() {
        const missing = this._missingPassportFields;
        if (!missing || missing.length === 0) {
            this._lastUnmatchedPassportFieldsKey = null;
            this._lastAlreadyFilledFieldKey = null;
            this._dispatchPassportWarningChange(false);
            return;
        }
        const missingApiNames = new Set(missing.map(entry => entry?.apiName ?? entry));
        let hasWarning = false;
        let alreadyFilledField = null;
        this.fields = this.fields.map(f => {
            if (!missingApiNames.has(f.id)) return f;
            if (f.isHidden) {
                return f.isHighlighted ? { ...f, isHighlighted: false } : f;
            }
            const isEmpty = f.value === null || f.value === undefined || f.value === '';
            if (isEmpty) {
                hasWarning = true;
            } else {
                alreadyFilledField = f;
            }
            return f.isHighlighted === isEmpty ? f : { ...f, isHighlighted: isEmpty };
        });
        if (this.isSingleFieldWarning) {
            this._notifyUnmatchedPassportFields(missing);
            this._notifyAlreadyFilledField(alreadyFilledField);
        }
        this._dispatchPassportWarningChange(hasWarning);
    }

    // Warns the user (and asks them to notify an administrator) when a single field requested via
    // dmt_missingFieldsPopover isn't actually present on this tab (e.g. missing from
    // dmt_opp_client_fields.js, or a stale/typo'd Field_Api_Name__c in
    // DMT_FieldsRequiredPassport__mdt). Only called when isSingleFieldWarning is true, and deduped
    // so it only fires once per distinct set of unmatched fields.
    _notifyUnmatchedPassportFields(missing) {
        const knownFieldIds = new Set(this.fields.map(f => f.id));
        const unmatched = missing.filter(entry => !knownFieldIds.has(entry?.apiName ?? entry));

        if (unmatched.length === 0) {
            this._lastUnmatchedPassportFieldsKey = null;
            return;
        }

        const unmatchedKey = unmatched.map(entry => entry?.apiName ?? entry).sort().join('|');
        if (unmatchedKey === this._lastUnmatchedPassportFieldsKey) return;
        this._lastUnmatchedPassportFieldsKey = unmatchedKey;

        const labels = unmatched.map(entry => entry?.label || entry?.apiName || entry).join(', ');
        this.dispatchEvent(new ShowToastEvent({
            title: 'Field not found',
            message: `We couldn't find the field(s) "${labels}" on this tab. Please search for it manually and notify an administrator so it can be configured.`,
            variant: 'warning',
            mode: 'sticky'
        }));
    }

    // Tells the user that the single field they clicked from dmt_missingFieldsPopover already has
    // a value (so there's nothing to highlight), and that the Passport should be refreshed to
    // reflect it. Deduped so it only fires once per field.
    _notifyAlreadyFilledField(field) {
        if (!field) {
            this._lastAlreadyFilledFieldKey = null;
            return;
        }
        if (field.id === this._lastAlreadyFilledFieldKey) return;
        this._lastAlreadyFilledFieldKey = field.id;

        this.dispatchEvent(new ShowToastEvent({
            title: 'Field already filled in',
            message: `"${field.label}" already has a value. Please update the Passport so it reflects the current data.`,
            variant: 'info',
            mode: 'dismissable'
        }));
    }

    _dispatchPassportWarningChange(hasWarning) {
        this.dispatchEvent(new CustomEvent('passportwarningchange', {
            detail: { hasWarning },
            bubbles: true,
            composed: true
        }));
    }

    _exitEditMode() {
        this._snapshot = null;
        this.isEditMode = false;
        this.hasError = false;
        this.errorMessage = '';
        this.notifyEditMode(false);
    }

    _showErrorToast(message, title = 'Error') {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant: 'error', mode: 'dismissable' })
        );
    }

    // ─── Error handling (centralised for load + save) ───────────────────────────
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
            lower.includes('callout') ||
            lower.includes('read timed out')
        ) {
            return 'The HPG service is currently unavailable. Please try again in a few minutes.';
        }

        // For all other errors, show the actual message from the server
        return (
            rawMessage ||
            (context === 'save'
                ? 'Unable to save your changes. Please try again.'
                : 'Unable to load client information. Please try again.')
        );
    }


    _extractErrorMessage(error) {
        if (!error) return DEFAULT_ERROR_MESSAGE;

        const acc = { dml: [], text: [] };
        this._walkError(error, acc, new Set(), 0);

        const dedupe = list => [...new Set(list.filter(Boolean))];

        // DML errors (required field, validation rules, etc.) take priority.
        const dmlMessages = dedupe(acc.dml);
        if (dmlMessages.length) return dmlMessages.join(' | ');

        // Otherwise use the best plain-text message found.
        const textMessages = dedupe(acc.text);
        if (textMessages.length) return textMessages.join(' | ');

        return DEFAULT_ERROR_MESSAGE;
    }


    _walkError(node, acc, seen, depth) {
        if (node == null || depth > 6) return;

        if (typeof node === 'string') {
            const parsed = this._tryParseJson(node);
            if (parsed !== null) {
                this._walkError(parsed, acc, seen, depth + 1);
            } else {
                this._pushMessage(acc.text, node);
            }
            return;
        }

        if (typeof node !== 'object' || seen.has(node)) return;
        seen.add(node);

        if (Array.isArray(node)) {
            node.forEach(item => this._walkError(item, acc, seen, depth + 1));
            return;
        }

        // ── DML result structures (Database.SaveResult style) ─────────────────
        if (node.fieldErrors && typeof node.fieldErrors === 'object') {
            Object.values(node.fieldErrors).forEach(errs => {
                (Array.isArray(errs) ? errs : [errs]).forEach(e =>
                    this._pushMessage(acc.dml, e && e.message)
                );
            });
        }
        if (Array.isArray(node.pageErrors)) {
            node.pageErrors.forEach(e => this._pushMessage(acc.dml, e && e.message));
        }
        if (Array.isArray(node.errors)) {
            node.errors.forEach(e => this._pushMessage(acc.dml, e && e.message));
        }
        if (Array.isArray(node.duplicateResults) && node.duplicateResults.length) {
            acc.dml.push('A duplicate record was detected.');
        }

        // ── Container fields that may wrap the real payload ───────────────────
        this._walkError(node.body, acc, seen, depth + 1);
        this._walkError(node.output, acc, seen, depth + 1);
        if (typeof node.message === 'string') {
            this._walkError(node.message, acc, seen, depth + 1);
        }
    }

    _pushMessage(target, message) {
        if (!message) return;
        const text = String(message).trim();
        if (text && !PLACEHOLDER_MESSAGES.has(text.toLowerCase())) target.push(text);
    }

    _tryParseJson(value) {
        if (typeof value !== 'string') return null;
        const trimmed = value.trim();
        if (!trimmed || (trimmed[0] !== '{' && trimmed[0] !== '[')) return null;
        try {
            return JSON.parse(trimmed);
        } catch (_) {
            return null;
        }
    }
    notifyEditMode(value) {
        this.dispatchEvent(new CustomEvent('editmodetab', {
            detail   : { editMode: value },
            bubbles  : true,
            composed : true
        }));
    }
}