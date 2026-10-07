import { LightningElement, api, track, wire } from 'lwc';
import { businessPlanFields, extraBusinessPlanFields } from './dmt_opp_approval_business_plan_fields';
import LightningConfirm from 'lightning/confirm';
import getBusinessPlanOpportunity from '@salesforce/apex/DMT_BussinessPlanController.getBussinessPlan';
import getBussinessPlanByClient   from '@salesforce/apex/DMT_BussinessPlanController.getBussinessPlanByClient';
import getTaxonomyCatalogValues   from '@salesforce/apex/DMT_ApprovalDataController.getTaxonomyCatalogValues';
import saveApprovalData           from '@salesforce/apex/DMT_ApprovalDataController.saveApprovalData';
import pubsub                     from 'omnistudio/pubsub';

// Fields stored per geography on DMT_Opportunity_Business_Plan__c (not on DMT_Opportunity_Client__c)
// These live in extraFields and are universal: same value across ALL BP records.
const BP_EXTRA_FIELDS = new Set(['DMT_QAOTER__c']);

// Fields in the `fields` array that are geography-specific (saved only to current geo records)
const BP_GEO_FIELDS = new Set(['DMT_Active__c']);

// Fields in the `fields` array that must be saved to ALL BP records (universal),
// not just the current geography. They live in `fields` for UI layout purposes.
const BP_UNIVERSAL_FIELDS = new Set(['DMT_Currency__c']);

// Hardcoded geography options for DMT_Booking_Geography__c picklist
const GEO_OPTIONS = [
    { label: 'GLOBAL', value: 'GLOBAL' },
    { label: 'SPAIN', value: 'SPAIN' },
    { label: 'FRANCE', value: 'FRANCE' },
    { label: 'ITALY', value: 'ITALY' },
    { label: 'GERMANY', value: 'GERMANY' },
    { label: 'UK', value: 'UK' },
    { label: 'ASIA', value: 'ASIA' },
    { label: 'NY', value: 'NY' },
    { label: 'BRASIL', value: 'BRASIL' },
    { label: 'MEXICO', value: 'MEXICO' },
    { label: 'COLOMBIA', value: 'COLOMBIA' },
    { label: 'PERU', value: 'PERU' },
    { label: 'CHILE', value: 'CHILE' },
    { label: 'ARGENTINA', value: 'ARGENTINA' },
    { label: 'TURKEY', value: 'TURKEY' },
    { label: 'OTHERS', value: 'OTHERS' }
];

export default class Dmt_opp_approval_business_plan extends LightningElement {

    // isEditMode is @api so FlexCards can bind it directly (account case).
    // The opportunity parent uses the enterEditMode() / commitEdit() methods instead.
    _isEditMode = false;
    @api
    get isEditMode() { return this._isEditMode; }
    set isEditMode(value) {
        const newVal = value === true || value === 'true';
        if (newVal === this._isEditMode) return;
        this._isEditMode = newVal;
        if (newVal) {
            // Try to snapshot now; if data isn't loaded yet, _recompute() will retry
            this._tryTakeEditModeSnapshot();
        } else {
            this._snapshot      = null;
            this._extraSnapshot = null;
        }
    }

    @api
    get recordId() { return this._recordId; }
    set recordId(value) {
        this._recordId = value;
        if (value) {
            this._loadBPRecords();
            // For account (FlexCard): fieldOptions is never set by parent — apply
            // self-loaded catalog values if the wire already fired before recordId was set
            if (this._isAccountId(value) && this._taxonomyCatalogData) {
                this._applyTaxonomyCatalogValues(this._taxonomyCatalogData);
            }
        }
    }

    @api groupId;
    @api opportunityClientId;
    @api stageRecord;

    canEdit = true;
    _selectedGeography = 'GLOBAL';
    _recordId;
    @track _bpRecords = null;   // DMT_Opportunity_Business_Plan__c records, fetched here and passed down
    @track _accountBpRecords = null; // Account comparison BP records for Redo
    _taxonomyCatalogData = null; // self-loaded for account case (FlexCard)

    // ─── Computed pass-through properties for inner table ─────────────────────
    get isOpportunity() { return true; }
    get isClient()      { return false; }
    get isOppView()     { return !this._isAccountId(this._recordId); }
    get stageName()     {
        // Account case: no opportunity stage, always allow editing
        if (this._isAccountId(this._recordId)) return 'Draft';
        return this._data?.DMT_MDE_Opportunity__r?.StageName ?? this.stageRecord ?? null;
    }

    get closeDate() {
        if (this._isAccountId(this._recordId)) {
            return null;
        }

        return this._data
            ?.DMT_MDE_Opportunity__r
            ?.CloseDate ?? null;
    }

    get isClosed() {
        const value =
            this._data?.DMT_MDE_Opportunity__r?.IsClosed
            ?? false;

        return value === true || value === 'true';
    }

    @api
    get isReadOnlyUser(){ return this.canEdit !== true; }
    set isReadOnlyUser(value) {
        const readOnly = value === true || value === 'true';
        // Delegate to setReadOnlyMode so field snapshotting also occurs
        if (readOnly !== (this.canEdit !== true)) {
            this.setReadOnlyMode(readOnly);
        }
    }

    @track fields      = [...businessPlanFields];
    @track extraFields = [...extraBusinessPlanFields];

    _fieldsOriginal     = [...businessPlanFields];
    _extraOriginal      = [...extraBusinessPlanFields];
    _data;
    _options            = {};
    _snapshot           = null;
    _extraSnapshot      = null;
    _readOnlySnapshot   = null;
    _extraReadOnlySnapshot = null;

    // ─── Public API ───────────────────────────────────────────────────────────

    @api get data() { return this._data; }
    set data(value) {
        console.log('dmt_opp_approval_business_plan: data set', JSON.stringify(value));
        this._data = value;
        if (value) {
            console.log('dmt_opp_approval_business_plan: data set', JSON.stringify(value));
        }
        if (!this._snapshot) {
            this._recompute();
        }
    }

    @api get fieldOptions() { return this._options; }
    set fieldOptions(value) {
        // Opportunity case: catalog values provided by parent component
        this._applyTaxonomyCatalogValues(value.catalogValues);
    }

    @api enterEditMode() {
        this._snapshot      = this.fields.map(f => ({ ...f }));
        this._extraSnapshot = this.extraFields.map(f => ({ ...f }));
        this._isEditMode    = true;
    }

    @api restoreSnapshot() {
        if (this._snapshot)      this.fields      = this._snapshot;
        if (this._extraSnapshot) this.extraFields  = this._extraSnapshot;
        this._snapshot      = null;
        this._extraSnapshot = null;
        // Discard unsaved BP table edits on cancel
        this.refs?.tableBusinessPlan?.reset?.();
    }

    @api commitEdit() {
        this._snapshot      = null;
        this._extraSnapshot = null;
        this._isEditMode    = false;
    }

    @api setReadOnlyMode(readOnly) {
        this.canEdit = !readOnly;
        if (readOnly) {
            // Snapshot original isReadOnly values before forcing everything to true,
            // so they can be correctly restored when read-only mode is lifted
            if (!this._readOnlySnapshot) {
                this._readOnlySnapshot      = this.fields.map(f => ({ id: f.id, isReadOnly: f.isReadOnly }));
                this._extraReadOnlySnapshot = this.extraFields.map(f => ({ id: f.id, isReadOnly: f.isReadOnly }));
            }
            this.fields      = this.fields.map(f => ({ ...f, isReadOnly: true }));
            this.extraFields = this.extraFields.map(f => ({ ...f, isReadOnly: true }));
        } else {
            if (!this._readOnlySnapshot) {
                return;
            }
            // Restore each field's original isReadOnly value from the snapshot
            const roMap      = new Map(this._readOnlySnapshot.map(f => [f.id, f.isReadOnly]));
            const roExtraMap = new Map(this._extraReadOnlySnapshot.map(f => [f.id, f.isReadOnly]));
            this.fields      = this.fields.map(f => ({ ...f, isReadOnly: roMap.has(f.id) ? roMap.get(f.id) : f.isReadOnly }));
            this.extraFields = this.extraFields.map(f => ({ ...f, isReadOnly: roExtraMap.has(f.id) ? roExtraMap.get(f.id) : f.isReadOnly }));
            this._readOnlySnapshot      = null;
            this._extraReadOnlySnapshot = null;
        }
    }

    @api collectChanges() {
        const result = {};
        //this._collectFromArray(result, this.fields, this._snapshot);
        //this._collectFromArray(result, this.extraFields, this._extraSnapshot);
        return result;
    }

    /**
     * Returns true when the BP table has unsaved row edits or extra/geo fields changed.
     * Used by the parent to detect dirty state for the tab indicator.
     */
    @api get hasPendingChanges() {
        // Table row edits
        if (this.refs?.tableBusinessPlan?.hasPendingChanges) return true;
        // Extra fields (QAOTER)
        if (this._extraSnapshot) {
            const snapMap = new Map(this._extraSnapshot.map(f => [f.apiName, f.value]));
            for (const f of this.extraFields) {
                if (!BP_EXTRA_FIELDS.has(f.apiName)) continue;
                if (String(f.value ?? '') !== String(snapMap.get(f.apiName) ?? '')) return true;
            }
        }
        // Geography-specific fields (DMT_Active__c) and universal fields (DMT_Currency__c)
        if (this._snapshot) {
            const snapMap = new Map(this._snapshot.map(f => [f.apiName, f.value]));
            for (const f of this.fields) {
                if (!BP_GEO_FIELDS.has(f.apiName) && !BP_UNIVERSAL_FIELDS.has(f.apiName)) continue;
                if (String(f.value ?? '') !== String(snapMap.get(f.apiName) ?? '')) return true;
            }
        }
        return false;
    }

    @api getFieldLabel(apiName) {
        const f = this.fields.find(x => x.apiName === apiName) ||
                  this.extraFields.find(x => x.apiName === apiName);
        return f ? f.label : null;
    }

    get bookingGeography() {
        return this._selectedGeography;
    }

    /**
     * Collects BP table changes and returns them to the parent for unified Apex save.
     * DMT_QAOTER__c and DMT_Currency__c have the SAME value across ALL BP records
     * (regardless of booking geography), so changes are applied to every existing record.
     * Returns an array of { Id, Field__c: value } update objects (may be empty).
     */
    @api
    collectBpChanges() {
        const tableChanges = this.refs?.tableBusinessPlan?.collectBpChanges?.() ?? [];

        // Detect changes to BP-level extra fields (QAOTER / Currency)
        if (this._extraSnapshot) {
            const snapMap = new Map(this._extraSnapshot.map(f => [f.apiName, f.value]));
            const extraFieldChanges = {};
            this.extraFields.forEach(f => {
                if (!BP_EXTRA_FIELDS.has(f.apiName)) return;
                const snapVal = snapMap.get(f.apiName);
                if (String(f.value ?? '') !== String(snapVal ?? '')) {
                    extraFieldChanges[f.apiName] = (f.value === '' || f.value === undefined) ? null : f.value;
                }
            });

            if (Object.keys(extraFieldChanges).length > 0) {
                // Apply to ALL existing BP records (universal value, independent of geography)
                const allRecordIds = (this._bpRecords || [])
                    .filter(r => r.Id)
                    .map(r => r.Id);

                allRecordIds.forEach(id => {
                    const existing = tableChanges.find(u => u.Id === id);
                    if (existing) {
                        Object.assign(existing, extraFieldChanges);
                    } else {
                        tableChanges.push({ Id: id, ...extraFieldChanges });
                    }
                });

                // Also propagate into new-record objects already in tableChanges (those without Id)
                tableChanges.filter(u => !u.Id).forEach(u => Object.assign(u, extraFieldChanges));

                // If no existing records and no new-record stubs in tableChanges,
                // create new BP records for all years in the current geography
                if (allRecordIds.length === 0 && tableChanges.length === 0) {
                    const stubs = this._buildNewRecordStubs(this._selectedGeography);
                    stubs.forEach(s => tableChanges.push({ ...s, ...extraFieldChanges }));
                }
            }
        }

        // Detect changes to geography-specific fields (DMT_Active__c)
        if (this._snapshot) {
            const snapMap = new Map(this._snapshot.map(f => [f.apiName, f.value]));
            const geoFieldChanges = {};
            this.fields.forEach(f => {
                if (!BP_GEO_FIELDS.has(f.apiName)) return;
                // GLOBAL is always active — force true regardless of UI state
                const currentValue = (f.apiName === 'DMT_Active__c' && this._selectedGeography === 'GLOBAL')
                    ? true
                    : f.value;
                const snapVal = snapMap.get(f.apiName);
                console.log('[BP-GEO] collectBpChanges checking', f.apiName, '| current:', currentValue, '| snapshot:', snapVal);
                if (String(currentValue ?? '') !== String(snapVal ?? '')) {
                    geoFieldChanges[f.apiName] = (currentValue === '' || currentValue === undefined) ? null : currentValue;
                }
            });

            // For GLOBAL: always force DMT_Active__c = true even if snapshot already had true
            // (ensures it is persisted to DB on first save)
            if (this._selectedGeography === 'GLOBAL') {
                geoFieldChanges['DMT_Active__c'] = true;
            }

            console.log('[BP-GEO] geoFieldChanges:', JSON.stringify(geoFieldChanges));

            if (Object.keys(geoFieldChanges).length > 0) {
                // Apply only to BP records of the CURRENT geography
                const geoRecordIds = (this._bpRecords || [])
                    .filter(r => r.Id && r.DMT_Booking_Geography__c === this._selectedGeography)
                    .map(r => r.Id);

                console.log('[BP-GEO] geoRecordIds for geography', this._selectedGeography, ':', JSON.stringify(geoRecordIds));

                geoRecordIds.forEach(id => {
                    const existing = tableChanges.find(u => u.Id === id);
                    if (existing) {
                        Object.assign(existing, geoFieldChanges);
                    } else {
                        tableChanges.push({ Id: id, ...geoFieldChanges });
                    }
                });

                // Also propagate into new-record objects in tableChanges that match current geography
                tableChanges
                    .filter(u => !u.Id && u.DMT_Booking_Geography__c === this._selectedGeography)
                    .forEach(u => Object.assign(u, geoFieldChanges));

                // If no existing geo records and no matching new-record stubs, create them
                const hasGeoStubs = tableChanges.some(u => !u.Id && u.DMT_Booking_Geography__c === this._selectedGeography);
                if (geoRecordIds.length === 0 && !hasGeoStubs) {
                    const stubs = this._buildNewRecordStubs(this._selectedGeography);
                    stubs.forEach(s => tableChanges.push({ ...s, ...geoFieldChanges }));
                }
            }
        }

        // Detect changes to universal fields that live in `fields` (e.g. DMT_Currency__c)
        // These apply to ALL BP records regardless of geography.
        if (this._snapshot) {
            const snapMap = new Map(this._snapshot.map(f => [f.apiName, f.value]));
            const universalFieldChanges = {};
            this.fields.forEach(f => {
                if (!BP_UNIVERSAL_FIELDS.has(f.apiName)) return;
                const snapVal = snapMap.get(f.apiName);
                if (String(f.value ?? '') !== String(snapVal ?? '')) {
                    universalFieldChanges[f.apiName] = (f.value === '' || f.value === undefined) ? null : f.value;
                }
            });

            if (Object.keys(universalFieldChanges).length > 0) {
                // Apply to ALL existing BP records (universal value, independent of geography)
                const allRecordIds = (this._bpRecords || [])
                    .filter(r => r.Id)
                    .map(r => r.Id);

                allRecordIds.forEach(id => {
                    const existing = tableChanges.find(u => u.Id === id);
                    if (existing) {
                        Object.assign(existing, universalFieldChanges);
                    } else {
                        tableChanges.push({ Id: id, ...universalFieldChanges });
                    }
                });

                // Also propagate into new-record objects already in tableChanges
                tableChanges.filter(u => !u.Id).forEach(u => Object.assign(u, universalFieldChanges));

                // If no existing records and no new-record stubs, create stubs
                if (allRecordIds.length === 0 && tableChanges.length === 0) {
                    const stubs = this._buildNewRecordStubs(this._selectedGeography);
                    stubs.forEach(s => tableChanges.push({ ...s, ...universalFieldChanges }));
                }
            }
        }

        // GLOBAL is ALWAYS active — ensure DMT_Active__c = true on all GLOBAL BP records
        // regardless of which geography is currently selected
        if (this._selectedGeography !== 'GLOBAL') {
            const globalRecordIds = (this._bpRecords || [])
                .filter(r => r.Id && r.DMT_Booking_Geography__c === 'GLOBAL')
                .map(r => r.Id);

            globalRecordIds.forEach(id => {
                const existing = tableChanges.find(u => u.Id === id);
                if (existing) {
                    existing['DMT_Active__c'] = true;
                } else {
                    tableChanges.push({ Id: id, DMT_Active__c: true });
                }
            });

            // Also propagate into new GLOBAL records in tableChanges
            tableChanges
                .filter(u => !u.Id && u.DMT_Booking_Geography__c === 'GLOBAL')
                .forEach(u => { u['DMT_Active__c'] = true; });
        }

        // Business Plan is always in EUR
        this._forceEur(tableChanges);

        console.log('[BP] collectBpChanges final result:', JSON.stringify(tableChanges));
        return tableChanges;
    }

    /**
     * Business Plan is always in EUR (currency selector removed).
     * Must be applied as the last step of every save path (Opportunity, Account, Redo).
     */
    _forceEur(updates) {
        // Include any existing BP record not yet in EUR, so it gets normalised on save
        (this._bpRecords || [])
            .filter(r => r.Id && r.DMT_Currency__c !== 'EUR')
            .forEach(r => {
                if (!updates.some(u => u.Id === r.Id)) {
                    updates.push({ Id: r.Id });
                }
            });
        // Force EUR on everything that is going to be saved (updates and new-record stubs)
        updates.forEach(u => { u.DMT_Currency__c = 'EUR'; });
        return updates;
    }

    /**
     * Called by the parent after a successful Apex save to clear stale table state
     * and reload fresh BP records from the org.
     */
    @api
    async refreshAfterSave() {
        this.refs?.tableBusinessPlan?.clearPendingEdits?.();
        await this._loadBPRecords();
    }

    /**
     * Salesforce key-prefix detection:
     *   001… → Account     → query by DMT_Client__c
     *   006… → Opportunity → query by DMT_Opportunity__c
     */
    _isAccountId(id) {
        return typeof id === 'string' && id.startsWith('001');
    }

    /**
     * Creates new-record stub objects for all 5 years in the given geography.
     * Used when extra fields are modified but no BP records exist yet.
     */
    _buildNewRecordStubs(geography) {
        const y = new Date().getFullYear();
        const q = Math.ceil((new Date().getMonth() + 1) / 3);
        const offset = q === 4 ? 1 : 0;
        const stubs = [];
        for (let i = 0; i < 5; i++) {
            const year = y - 2 + i + offset;
            const stub = {
                DMT_Year__c: String(year),
                DMT_Booking_Geography__c: geography
            };
            if (this._isAccountId(this._recordId)) {
                stub.DMT_Client__c = this._recordId;
            } else {
                stub.DMT_Opportunity__c = this._recordId;
            }
            stubs.push(stub);
        }
        return stubs;
    }

    // ─── Lifecycle ────────────────────────────────────────────────────────────

    connectedCallback() {
        // Register PubSub Save handler for account/FlexCard case.
        // For opportunity the parent (dmt_opp_approval_details) manages saving.
        this._pubsubSaveHandlers = {
            DMT_CLIENT_GROUP_V2: this._handleAccountSave.bind(this)
        };
        pubsub.register('Save', this._pubsubSaveHandlers);
    }

    disconnectedCallback() {
        pubsub.unregister('Save', this._pubsubSaveHandlers);
    }

    /**
     * Handles the FlexCard Save PubSub event (account case only).
     * Collects ALL changes (table row edits + QAOTER/Currency) and persists them
     * via Apex saveApprovalData (upsert). This is the single save path for Account:
     * the inner table's handleSave is disabled in preloadedRecords mode.
     * After a successful save, fires Button:BusinessSave to signal the FlexCard.
     */
    async _handleAccountSave() {
        console.log('[OPP-APPROVAL-BP] _handleAccountSave FIRED. recordId=', this._recordId);
        // Opportunity is saved by the parent component — ignore here
        if (!this._isAccountId(this._recordId)) return;

        try {
            // 1. Collect row-level table changes from the inner table (builds update objects
            //    including new-record context fields like DMT_Year__c, DMT_Booking_Geography__c)
            const tableChanges = this.refs?.tableBusinessPlan?.collectBpChanges?.() ?? [];

            // 2. Read current QAOTER/Currency values from extraFields directly.
            const extraFieldValues = {};
            this.extraFields.forEach(f => {
                if (BP_EXTRA_FIELDS.has(f.apiName)) {
                    extraFieldValues[f.apiName] = (f.value === '' || f.value == null) ? null : f.value;
                }
            });

            // 3. Merge QAOTER/Currency into every update object (universal across all records)
            const allUpdates = [...tableChanges];
            if (Object.keys(extraFieldValues).length > 0) {
                // Apply to all table change objects
                allUpdates.forEach(u => Object.assign(u, extraFieldValues));
                // Also apply to existing BP records that aren't already in table changes
                const updatedIds = new Set(allUpdates.filter(u => u.Id).map(u => u.Id));
                (this._bpRecords || []).filter(r => r.Id && !updatedIds.has(r.Id)).forEach(r => {
                    allUpdates.push({ Id: r.Id, ...extraFieldValues });
                });

                // If no existing records and no table changes, create new BP record stubs
                if (allUpdates.length === 0) {
                    const stubs = this._buildNewRecordStubs(this._selectedGeography);
                    stubs.forEach(s => allUpdates.push({ ...s, ...extraFieldValues }));
                }
            }

            // 3b. Merge geography-specific fields (DMT_Active__c) only into current geography records
            const geoFieldValues = {};
            this.fields.forEach(f => {
                if (BP_GEO_FIELDS.has(f.apiName)) {
                    geoFieldValues[f.apiName] = (f.value === '' || f.value == null) ? null : f.value;
                }
            });
            if (Object.keys(geoFieldValues).length > 0) {
                const geoRecordIds = new Set(
                    (this._bpRecords || [])
                        .filter(r => r.Id && r.DMT_Booking_Geography__c === this._selectedGeography)
                        .map(r => r.Id)
                );
                allUpdates.forEach(u => {
                    if (u.Id && geoRecordIds.has(u.Id)) Object.assign(u, geoFieldValues);
                    if (!u.Id && u.DMT_Booking_Geography__c === this._selectedGeography) Object.assign(u, geoFieldValues);
                });
                // Also apply to geo records not yet in allUpdates
                const alreadyUpdatedIds = new Set(allUpdates.filter(u => u.Id).map(u => u.Id));
                (this._bpRecords || [])
                    .filter(r => r.Id && geoRecordIds.has(r.Id) && !alreadyUpdatedIds.has(r.Id))
                    .forEach(r => { allUpdates.push({ Id: r.Id, ...geoFieldValues }); });

                // If no existing geo records and no matching stubs, create new records
                const hasGeoStubs = allUpdates.some(u => !u.Id && u.DMT_Booking_Geography__c === this._selectedGeography);
                if (geoRecordIds.size === 0 && !hasGeoStubs) {
                    const stubs = this._buildNewRecordStubs(this._selectedGeography);
                    stubs.forEach(s => allUpdates.push({ ...s, ...geoFieldValues }));
                }
            }

            // 3b2. Merge universal fields from `fields` (e.g. DMT_Currency__c) into ALL records
            const universalFieldValues = {};
            this.fields.forEach(f => {
                if (BP_UNIVERSAL_FIELDS.has(f.apiName)) {
                    universalFieldValues[f.apiName] = (f.value === '' || f.value == null) ? null : f.value;
                }
            });
            if (Object.keys(universalFieldValues).length > 0) {
                allUpdates.forEach(u => Object.assign(u, universalFieldValues));
                const updatedIds = new Set(allUpdates.filter(u => u.Id).map(u => u.Id));
                (this._bpRecords || []).filter(r => r.Id && !updatedIds.has(r.Id)).forEach(r => {
                    allUpdates.push({ Id: r.Id, ...universalFieldValues });
                });
                if (allUpdates.length === 0) {
                    const stubs = this._buildNewRecordStubs(this._selectedGeography);
                    stubs.forEach(s => allUpdates.push({ ...s, ...universalFieldValues }));
                }
            }

            // 3c. GLOBAL is ALWAYS active — force DMT_Active__c = true on GLOBAL records
            if (this._selectedGeography !== 'GLOBAL') {
                const globalRecordIds = (this._bpRecords || [])
                    .filter(r => r.Id && r.DMT_Booking_Geography__c === 'GLOBAL')
                    .map(r => r.Id);
                globalRecordIds.forEach(id => {
                    const existing = allUpdates.find(u => u.Id === id);
                    if (existing) {
                        existing['DMT_Active__c'] = true;
                    } else {
                        allUpdates.push({ Id: id, DMT_Active__c: true });
                    }
                });
                allUpdates
                    .filter(u => !u.Id && u.DMT_Booking_Geography__c === 'GLOBAL')
                    .forEach(u => { u['DMT_Active__c'] = true; });
            } else {
                // Currently on GLOBAL — force true on all GLOBAL updates
                allUpdates.forEach(u => {
                    const isGlobal = u.DMT_Booking_Geography__c === 'GLOBAL' ||
                        ((this._bpRecords || []).find(r => r.Id === u.Id)?.DMT_Booking_Geography__c === 'GLOBAL');
                    if (isGlobal) u['DMT_Active__c'] = true;
                });
            }

            // 4. Fix context fields: replace DMT_Opportunity__c (Account ID) with DMT_Client__c
            allUpdates.forEach(u => {
                if (u.DMT_Opportunity__c && this._isAccountId(u.DMT_Opportunity__c)) {
                    delete u.DMT_Opportunity__c;
                    u.DMT_Client__c = this._recordId;
                }
                // New records without DMT_Opportunity__c or DMT_Client__c: set DMT_Client__c
                if (!u.Id && !u.DMT_Opportunity__c && !u.DMT_Client__c) {
                    u.DMT_Client__c = this._recordId;
                }
            });


            // 4b. Business Plan is always in EUR          
            this._forceEur(allUpdates);

            // 5. If nothing to save, still signal success to complete the FlexCard coordination
            if (allUpdates.length === 0) {
                pubsub.fire('Button', 'BusinessSave', {});
                return;
            }

            // 6. Persist via Apex (supports both insert and update via upsert)
            await saveApprovalData({
                recordFields        : {},
                opportunityClientId : null,
                bpChangesJson       : JSON.stringify(allUpdates)
            });

            // 7. Clear table pending edits and reload fresh data
            this.refs?.tableBusinessPlan?.clearPendingEdits?.();
            await this._loadBPRecords();

            // 8. Clear snapshot state
            this._snapshot      = null;
            this._extraSnapshot = null;

            // 9. Signal FlexCard that ALL save steps are complete (Account owns the full save)
            pubsub.fire('Button', 'OmniSave', {});
            pubsub.fire('Button', 'FinancialsSave', {});
            pubsub.fire('Button', 'BusinessSave', {});
        } catch (e) {
            console.error('[dmt_opp_approval_business_plan] Error saving account BP data:', e);
            pubsub.fire('Set', 'Error', { errorMessage: e.body?.message || e.message || 'Error saving Business Plan data' });
        }
    }

    /**
     * Handles the 'redosave' event dispatched by the inner BP table after a Redo action.
     * Collects all pending changes and persists them via Apex (works for both Account and Opportunity).
     */
    async _handleRedoSave() {
        console.log('[OPP-APPROVAL-BP] _handleRedoSave FIRED');
        try {
            const tableChanges = this.refs?.tableBusinessPlan?.collectBpChanges?.() ?? [];
            console.log('[OPP-APPROVAL-BP] tableChanges count:', tableChanges.length, JSON.stringify(tableChanges));
            if (tableChanges.length === 0) {
                // Nothing to save — still signal FlexCard completion for account case
                if (this._isAccountId(this._recordId)) {
                    pubsub.fire('Button', 'BusinessSave', {});
                }
                return;
            }

            const isAccount = this._isAccountId(this._recordId);

            // Fix context fields: Account uses DMT_Client__c, Opportunity uses DMT_Opportunity__c
            tableChanges.forEach(u => {
                if (isAccount) {
                    if (u.DMT_Opportunity__c && this._isAccountId(u.DMT_Opportunity__c)) {
                        delete u.DMT_Opportunity__c;
                        u.DMT_Client__c = this._recordId;
                    }
                    if (!u.Id && !u.DMT_Opportunity__c && !u.DMT_Client__c) {
                        u.DMT_Client__c = this._recordId;
                    }
                }
            });

            // Business Plan is always in EUR           
            this._forceEur(tableChanges);   

            await saveApprovalData({
                recordFields        : {},
                opportunityClientId : isAccount ? null : this.opportunityClientId,
                bpChangesJson       : JSON.stringify(tableChanges)
            });

            // Clear stale state and reload fresh data
            this.refs?.tableBusinessPlan?.clearPendingEdits?.();
            await this._loadBPRecords();

            // Signal FlexCard that save is complete (account case)
            if (this._isAccountId(this._recordId)) {
                pubsub.fire('Button', 'BusinessSave', {});
            }
        } catch (e) {
            console.error('[dmt_opp_approval_bp] Error saving redo changes:', e);
            pubsub.fire('Set', 'Error', { errorMessage: e.body?.message || e.message || 'Error saving redo changes' });
        }
    }

    async _loadBPRecords() {
        if (!this._recordId) return;
        try {
            const records = this._isAccountId(this._recordId)
                ? await getBussinessPlanByClient({ clientId: this._recordId })
                : await getBusinessPlanOpportunity({ recordId: this._recordId, bookingGeography: null });
            this._bpRecords = records || [];
            // For Opportunity: also load account comparison records for Redo
            if (!this._isAccountId(this._recordId)) {
                let accountId = this.groupId;
                if (!accountId) {
                    // Derive AccountId from the Opportunity relationship in BP records
                    const firstWithAccount = this._bpRecords.find(r => r.DMT_Opportunity__r && r.DMT_Opportunity__r.AccountId);
                    if (firstWithAccount) {
                        accountId = firstWithAccount.DMT_Opportunity__r.AccountId;
                    }
                }
                if (accountId) {
                    try {
                        this._accountBpRecords = await getBussinessPlanByClient({ clientId: accountId });
                        console.log('[dmt_opp_approval_bp] Loaded account comparison records:', this._accountBpRecords?.length);
                    } catch (accErr) {
                        console.error('[dmt_opp_approval_bp] Error loading account comparison records:', accErr);
                        this._accountBpRecords = [];
                    }
                } else {
                    this._accountBpRecords = [];
                }
            }
            // Refresh geography picklist options to include any geographies present in BP records
            // that may not be in the taxonomy catalog (e.g. custom/legacy values)
            this._refreshGeoOptions();
        } catch (e) {
            console.error('[dmt_opp_approval_business_plan] Error loading BP records:', e);
            this._bpRecords = [];
        }
    }

    /**
     * Wire: self-load taxonomy catalog values for the account/FlexCard case.
     * For the opportunity case the parent always sets fieldOptions explicitly,
     * so the wire result is only applied when recordId is an account.
     */
    @wire(getTaxonomyCatalogValues)
    _wiredTaxonomyCatalogValues({ data, error }) {
        if (!data) return;
        this._taxonomyCatalogData = data;
        // Only self-apply for account case; opportunity gets fieldOptions from parent
        if (this._isAccountId(this._recordId)) {
            this._applyTaxonomyCatalogValues(data);
        }
    }

    /**
     * Applies taxonomy catalog values to the internal options state and triggers a recompute.
     * Called either from the fieldOptions setter (opportunity) or the wire handler (account).
     */
    _applyTaxonomyCatalogValues(catalogValues) {
        this._options = {
            DMT_Currency__c          : catalogValues?.['C264'] || [],
            DMT_Booking_Geography__c : this._buildGeoOptions()
        };
        if (!this._snapshot) {
            this._recompute();
        }
    }

    /**
     * Returns the hardcoded geography options, merging with any extra geographies
     * found in existing BP records that are not in the standard list.
     */
    _buildGeoOptions() {
        const bpGeos = Array.isArray(this._bpRecords)
            ? [...new Set(this._bpRecords.map(r => r.DMT_Booking_Geography__c).filter(Boolean))]
            : [];
        const existing = new Set(GEO_OPTIONS.map(o => o.value));
        const extra = bpGeos.filter(g => !existing.has(g)).map(g => ({ label: g, value: g }));
        return [...GEO_OPTIONS, ...extra];
    }

    /**
     * Refreshes the displayed values of BP-level extra fields (QAOTER, Currency).
     * Since these fields are universal (same value across all records), the value is
     * read from the first record that has a non-empty value, regardless of geography.
     * Also updates the snapshot baseline so change detection stays correct.
     */
    _updateExtraFieldsFromBpRecords(geo) {
        if (!Array.isArray(this._bpRecords)) return;
        // DMT_QAOTER__c is universal (extraFields) — use the first non-null value found
        const universalValues = {};
        BP_EXTRA_FIELDS.forEach(apiName => {
            const record = this._bpRecords.find(r => r[apiName] != null && r[apiName] !== '');
            universalValues[apiName] = record?.[apiName] ?? '';
        });
        this.extraFields = this.extraFields.map(f =>
            BP_EXTRA_FIELDS.has(f.apiName) ? { ...f, value: universalValues[f.apiName] } : f
        );
        if (this._extraSnapshot) {
            this._extraSnapshot = this._extraSnapshot.map(f =>
                BP_EXTRA_FIELDS.has(f.apiName) ? { ...f, value: universalValues[f.apiName] } : f
            );
        }

        // Universal fields in `fields` (DMT_Currency__c) — same value across all records
        const universalFieldValues = {};
        BP_UNIVERSAL_FIELDS.forEach(apiName => {
            const record = this._bpRecords.find(r => r[apiName] != null && r[apiName] !== '');
            universalFieldValues[apiName] = record?.[apiName] ?? '';
        });

        // Geography-specific fields + universal fields: read from BP records
        this.fields = this.fields.map(f => {
            if (BP_UNIVERSAL_FIELDS.has(f.apiName)) {
                return { ...f, value: universalFieldValues[f.apiName] };
            }
            if (!BP_GEO_FIELDS.has(f.apiName)) return f;
            const geoValue = this._getGeoFieldValue(f.apiName);
            const isReadOnly = (f.apiName === 'DMT_Active__c' && this._selectedGeography === 'GLOBAL');
            return { ...f, value: geoValue, isReadOnly };
        });
        if (this._snapshot) {
            this._snapshot = this._snapshot.map(f => {
                if (BP_UNIVERSAL_FIELDS.has(f.apiName)) {
                    return { ...f, value: universalFieldValues[f.apiName] };
                }
                if (!BP_GEO_FIELDS.has(f.apiName)) return f;
                const geoValue = this._getGeoFieldValue(f.apiName);
                return { ...f, value: geoValue };
            });
        }
    }

    /**
     * Reads a geography-specific field value from BP records filtered by the current geography.
     * Returns the value from the first matching record, or '' if none found.
     * For GLOBAL geography, DMT_Active__c is always true.
     * For other geographies, DMT_Active__c defaults to false unless DB has true.
     */
    _getGeoFieldValue(apiName) {
        // GLOBAL geography is always active
        if (apiName === 'DMT_Active__c' && this._selectedGeography === 'GLOBAL') {
            return true;
        }
        if (!Array.isArray(this._bpRecords)) {
            // No records loaded yet — default Active to false for non-GLOBAL
            return apiName === 'DMT_Active__c' ? false : '';
        }
        const geoRecords = this._bpRecords.filter(
            r => r.DMT_Booking_Geography__c === this._selectedGeography
        );
        if (apiName === 'DMT_Active__c') {
            // Only return true if at least one record explicitly has true; otherwise false
            const record = geoRecords.find(r => r[apiName] === true);
            return record ? true : false;
        }
        const record = geoRecords.find(r => r[apiName] != null);
        return record?.[apiName] ?? '';
    }

    /** Re-compute the geography picklist and trigger a re-render of the form. */
    _refreshGeoOptions() {
        if (!this._options) return;
        this._options = { ...this._options, DMT_Booking_Geography__c: this._buildGeoOptions() };
        if (!this._snapshot) {
            this._recompute();
        }
    }

    // ─── Event handlers ───────────────────────────────────────────────────────

    handleEditModeChange(event) {
        this.dispatchEvent(new CustomEvent('editmodechange', { detail: event.detail }));
        // For account/FlexCard: signal the FlexCard to transition to edit state via PubSub
        if (this._isAccountId(this._recordId)) {
            pubsub.fire('Button', 'Edit', {});
        }
    }

    handleFieldChange(event) {
        const { fieldId, value } = event.detail;
        const idx   = this.fields.findIndex(f => f.id === fieldId);
        if (idx === -1) return;
        const field   = this.fields[idx];
        const apiName = field.apiName;

        // Track geography selection independently so the table filter reacts
        if (apiName === 'DMT_Booking_Geography__c') {
            console.log('dmt_opp_approval_business_plan: geography changed to', value);
            this._selectedGeography = value || 'GLOBAL';
            // Load the new geography's stored QAOTER/Currency values into the form fields
            this._updateExtraFieldsFromBpRecords(this._selectedGeography);
        }

        this._applyFieldChange(fieldId, idx, field, value);
    }

    handleExtraFieldChange(event) {
        const { fieldId, value } = event.detail;
        const idx = this.extraFields.findIndex(f => f.id === fieldId);
        if (idx === -1) return;
        const newArr  = this.extraFields.slice();
        newArr[idx]   = { ...this.extraFields[idx], value };
        this.extraFields = newArr;
        this.dispatchEvent(new CustomEvent('sectionchange', {
            detail: { apiName: newArr[idx].apiName, value }
        }));
        // Notify parent of dirty state for tab dot indicator
        this.dispatchEvent(new CustomEvent('fieldchange'));
    }

    /**
     * Re-dispatches the fieldchange event from the inner BP table so the
     * parent (dmt_opp_approval_details) can detect dirty state for the tab dot.
     */
    _handleTableFieldChange() {
        this.dispatchEvent(new CustomEvent('fieldchange'));
    }

    /**
     * Handles geography change from the inline picklist inside the table.
     * Syncs parent's _selectedGeography and updates the form field + extra fields.
     */
    _handleTableGeographyChange(event) {
        const newGeo = event.detail.value;
        console.log('[BP-PARENT] _handleTableGeographyChange:', newGeo);
        this._selectedGeography = newGeo;

        // Update the Geography field in the form so it stays in sync
        const geoIdx = this.fields.findIndex(f => f.apiName === 'DMT_Booking_Geography__c');
        if (geoIdx !== -1) {
            const newArr = this.fields.slice();
            newArr[geoIdx] = { ...newArr[geoIdx], value: newGeo };
            this.fields = newArr;
        }

        // Reload geo-specific field values (Active, Currency, QAOTER)
        this._updateExtraFieldsFromBpRecords(newGeo);
    }

    _applyFieldChange(fieldId, idx, field, value) {
        const apiName         = field.apiName;
        const normalizedValue = value;

        let newArr  = this.fields.slice();
        newArr[idx] = { ...field, value: normalizedValue };

        this.fields = newArr;
        this.dispatchEvent(new CustomEvent('sectionchange', {
            detail: { apiName, value: normalizedValue }
        }));
        // Notify parent of dirty state for tab dot indicator (skip geography selector changes)
        if (apiName !== 'DMT_Booking_Geography__c') {
            this.dispatchEvent(new CustomEvent('fieldchange'));
        }
    }

    // ─── Recompute / options / rules ──────────────────────────────────────────

    _recompute() {
        let next = this._applyOptions(this._fieldsOriginal, this._fieldsOriginal);
        // DMT_Booking_Geography__c always reflects _selectedGeography (works without _data)
        next = next.map(f => {
            if (f.apiName === 'DMT_Booking_Geography__c') {
                return { ...f, value: this._selectedGeography };
            }
            // Universal fields (DMT_Currency__c): read from any BP record (same across all)
            if (BP_UNIVERSAL_FIELDS.has(f.apiName)) {
                if (Array.isArray(this._bpRecords) && this._bpRecords.length > 0) {
                    const anyRecord = this._bpRecords.find(r => r[f.apiName] != null && r[f.apiName] !== '');
                    return { ...f, value: anyRecord?.[f.apiName] ?? '' };
                }
                return { ...f, value: this._data?.[f.apiName] ?? '' };
            }
            // Geography-specific fields: read from BP records filtered by current geography
            if (BP_GEO_FIELDS.has(f.apiName)) {
                const geoValue = this._getGeoFieldValue(f.apiName);
                // GLOBAL → Active is always true and read-only
                const isReadOnly = (f.apiName === 'DMT_Active__c' && this._selectedGeography === 'GLOBAL');
                return { ...f, value: geoValue, isReadOnly };
            }
            return this._data ? { ...f, value: this._data[f.apiName] } : f;
        });
        this.fields = next;

        let nextExtra = this._applyOptions(this._extraOriginal, this._extraOriginal);
        // BP_EXTRA_FIELDS: read from _bpRecords first (works for both account and opportunity)
        nextExtra = nextExtra.map(f => {
            if (BP_EXTRA_FIELDS.has(f.apiName)) {
                if (Array.isArray(this._bpRecords) && this._bpRecords.length > 0) {
                    const anyRecord = this._bpRecords.find(r => r[f.apiName] != null && r[f.apiName] !== '');
                    return { ...f, value: anyRecord?.[f.apiName] ?? '' };
                }
                return { ...f, value: this._data?.[f.apiName] ?? '' };
            }
            return this._data ? { ...f, value: this._data[f.apiName] } : f;
        });
        this.extraFields = nextExtra;

        // Re-apply forced read-only if the mode was active before recompute
        if (this._readOnlySnapshot) {
            this.fields      = this.fields.map(f => ({ ...f, isReadOnly: true }));
            this.extraFields = this.extraFields.map(f => ({ ...f, isReadOnly: true }));
        }

        // Take deferred snapshot if edit mode was entered before async data was ready.
        // Requires both taxonomy catalog (options) and BP records to be available.
        this._tryTakeEditModeSnapshot();
    }

    /**
     * Takes the edit-mode snapshot only when both async data sources are ready:
     *   - _taxonomyCatalogData (wire getTaxonomyCatalogValues)
     *   - _bpRecords (loadBPRecords)
     * Called from the isEditMode setter and at the end of _recompute().
     */
    _tryTakeEditModeSnapshot() {
        if (!this._isEditMode || this._snapshot) return;
        if (!this._taxonomyCatalogData && !this._data) return; // wait for options source
        if (this._bpRecords === null) return;                  // wait for BP records
        this._snapshot      = this.fields.map(f => ({ ...f }));
        this._extraSnapshot = this.extraFields.map(f => ({ ...f }));
    }

    _applyOptions(originalArray, sourceForRO) {
        const baseArr = originalArray.map(f => ({ ...f }));
        if (!this._options) return baseArr;
        return baseArr.map(f => {
            const options = this._options[f.apiName];
            if (!options) return f;
            const merged      = { ...f, options };
            const originalRO  = sourceForRO.find(o => o.apiName === f.apiName)?.isReadOnly;
            // Disable picklist fields when no options are available
            if (f.type === 'picklist' && !originalRO) {
                merged.isReadOnly = options.length === 0;
            }
            return merged;
        });
    }


    // ─── Change collection ────────────────────────────────────────────────────

    _collectFromArray(result, currentArr, snapshotArr) {
        const isExtra = currentArr === this.extraFields;
        if (!snapshotArr) return;

        const snapMap = new Map(snapshotArr.map(f => [f.id, f]));
        for (const f of currentArr) {
            if (this._isOriginallyReadOnly(f.apiName, isExtra)) continue;


            const original = snapMap.get(f.id);
            let hasChanged;
            hasChanged = String(f.value ?? '') !== String(original?.value ?? ''); 
            if (!hasChanged) continue;

            result[f.apiName] = (f.value === '' || f.value === undefined ? null : f.value);
        }
    }

    _isOriginallyReadOnly(apiName, isExtra = false) {
        const source   = isExtra ? this._extraOriginal : this._fieldsOriginal;
        const original = source.find(o => o.apiName === apiName);
        return original?.isReadOnly === true;
    }

    _normalizeToBoolean(value) {
        return value === true || value === 'true' || value === 'Yes';
    }
}