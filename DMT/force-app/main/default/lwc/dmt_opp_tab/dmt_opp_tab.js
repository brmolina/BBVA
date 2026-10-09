import { LightningElement, wire, api } from 'lwc';
import { CurrentPageReference }        from 'lightning/navigation';
import { getRecord }                   from 'lightning/uiRecordApi';
import PRODUCT_AREA_FIELD              from '@salesforce/schema/Opportunity.DMT_Product_Area__c';
import DMT_LABEL_MODAL_UNSAVED_CHANGES_TITLE from '@salesforce/label/c.DMT_Label_Modal_Unsaved_Changes_Title';
import DMT_LABEL_MODAL_UNSAVED_CHANGES_BODY  from '@salesforce/label/c.DMT_Label_Modal_Unsaved_Changes_Body';
import DMT_LABEL_BTN_EXIT_WITHOUT_SAVING     from '@salesforce/label/c.DMT_Label_Btn_Exit_Without_Saving';
import DMT_LABEL_BTN_KEEP_EDITING            from '@salesforce/label/c.DMT_Label_Btn_Keep_Editing';
 

const ALL_STAGES = new Set(['ALL']);

const TABS_CONFIG = [
    { id: 'opportunityInfo',      label: 'Opportunity Info',        isFlexcard: false, editableStages: new Set(['Draft', 'Ready to close']) },
    { id: 'client',               label: 'Client',                  isFlexcard: false, editableStages: new Set(['Draft', 'Ready to close']) },
    { id: 'products',             label: 'Products',                isFlexcard: false, editableStages: new Set(['Draft', 'Ready to close']) },
    { id: 'approvalProcessData',  label: 'Approval Process Data',   isFlexcard: false, editableStages: new Set(['Draft', 'Proposal']) },
    { id: 'IBFPIPELINE',          label: 'IB&F PIPELINE',  isFlexcard: false, editableStages: ALL_STAGES },
    { id: 'underwriting',         label: 'Underwriting',            isFlexcard: false, editableStages: ALL_STAGES },
    { id: 'participants',         label: 'Participants',             isFlexcard: true, editableStages: null  },
    { id: 'versions',             label: 'Versions',                isFlexcard: false, editableStages: null }
];

// Tabs hidden when DMT_Product_Area__c === 'GTB'
const GTB_HIDDEN_TABS = Object.freeze(['IBFPIPELINE']);

// Tabs editable when stageRecord === 'Approval' and the user has isTeamMemberApprovalEdit
const TEAM_MEMBER_APPROVAL_EDIT_TABS = Object.freeze(['ALL']);

export default class Dmt_opp_tab extends LightningElement {

    recordId;
    isLoading = false;

    // Config: which field API names are required per tab by the "Passport" service.
    // Provided by the parent (Dmt_opp_custom_page), which gets it from
    // c-cf-D-M-T_-small_-passport_-opportunity_v2. Defaults to an empty list per
    // tab until the parent sends real data.
    _isFieldWarningPassport = TABS_CONFIG.reduce((acc, tab) => { acc[tab.id] = []; return acc; }, {});

    @api
    get isFieldWarningPassport() {
        return this._isFieldWarningPassport;
    }
    set isFieldWarningPassport(value) {
        this._isFieldWarningPassport = value || {};
        this._maybeAutoActivateTab(this._isFieldWarningPassport);
    }

    // True when the whole Passport warning payload (across ALL tabs, not just the active one)
    // carries exactly one required field. Used by child tab components (e.g. dmt_opp_info) to
    // only show their "field not found" notice when the user selected a single field from
    // dmt_missingFieldsPopover, not when they picked "Review all" (multiple fields at once).
    get isSinglePassportFieldWarning() {
        return this._countWarningFields(this._isFieldWarningPassport) === 1;
    }

    _countWarningFields(warningMap) {
        return Object.values(warningMap || {})
            .filter(fields => Array.isArray(fields))
            .reduce((sum, fields) => sum + fields.length, 0);
    }

    _maybeAutoActivateTab(warningMap) {
        const entries = Object.entries(warningMap || {})
            .filter(([, fields]) => Array.isArray(fields) && fields.length > 0);

        if (this._countWarningFields(warningMap) !== 1) return;

        const [onlyTabId] = entries[0];
        if (!onlyTabId || onlyTabId === this._activeTabId) return;
        if (!TABS_CONFIG.some(t => t.id === onlyTabId)) return;

        this._activeTabId       = onlyTabId;
        this._pendingActivation = true;
    }

    // Live warning state per tab, reported by each child component via its
    // `passportwarningchange`-style event once it has checked its own fields.
    // Defaults to false until a tab's child component actually reports a warning.
    tabWarningState = TABS_CONFIG.reduce((acc, tab) => {
        acc[tab.id] = false;
        return acc;
    }, {});

    labels = {
        modalUnsavedChangesTitle: DMT_LABEL_MODAL_UNSAVED_CHANGES_TITLE,
        modalUnsavedChangesBody : DMT_LABEL_MODAL_UNSAVED_CHANGES_BODY,
        btnExitWithoutSaving    : DMT_LABEL_BTN_EXIT_WITHOUT_SAVING,
        btnKeepEditing          : DMT_LABEL_BTN_KEEP_EDITING
    };

    _permissionUserRecord = { accessLevel_read: false, accessLevel_edit: false };
    _stageRecord          = '';
    _permissionsReceived  = false;
    _stageReceived        = false;

    // ─── Public API ───────────────────────────────────────────────────────────

    @api get permissionUserRecord() { return this._permissionUserRecord; }
    set permissionUserRecord(value) {
        if (this._hasPermissionChanged(value)) {
            this._permissionUserRecord = value;
            this._permissionsReceived  = true;
        }
    }

    @api get stageRecord() { return this._stageRecord; }
    set stageRecord(value) {
        const newStage = value || '';
        if (newStage !== this._stageRecord) {
            this._stageRecord    = newStage;
            this._stageReceived  = true;
        }
    }

    // Both inputs (stage + permissions) must have arrived before returning true,
    // so that canEdit never momentarily returns true during initialisation.
    // Generic/default check (no specific tab), kept for backward compatibility
    // with anything still referencing the shared `canEdit`.
    @api get canEdit() {
        return this._isTabEditable();
    }

    // Per-tab editability: each tab can define its own set of editable stages
    // via TABS_CONFIG[].editableStages. The 'Approval' + isTeamMemberApprovalEdit
    // override always takes precedence, regardless of the tab.
    get canEditOpportunityInfo()     { return this._isTabEditable('opportunityInfo'); }
    get canEditClient()               { return this._isTabEditable('client'); }
    get canEditProducts()             { return this._isTabEditable('products'); }
    get canEditApprovalProcessData()  { return this._isTabEditable('approvalProcessData'); }
    get canEditIBFPipeline()          { return this._isTabEditable('IBFPIPELINE'); }
    get canEditUnderwriting()         { return this._isTabEditable('underwriting'); }



    @api set isEditing(value) { this._isEditing = value; }
    get isEditing()            { return this._isEditing; }

    @api async reloadAllTabsContent() {
        const activeTabId      = this._activeTabId;
        const activeConfig     = TABS_CONFIG.find(t => t.id === activeTabId);
        const isActiveFlexcard = activeConfig?.isFlexcard ?? false;

        // Single pass: hide non-active visited tabs + active tab if it is a Flexcard.
        // This collapses everything into one state write → one re-render.
        const updated = { ...this.visiblePanels };
        TABS_CONFIG.forEach(tab => {
            if (updated[tab.id] && (tab.id !== activeTabId || isActiveFlexcard)) {
                updated[tab.id] = false;
            }
        });
        this.visiblePanels = updated;

        // Restore the active Flexcard immediately so the user sees it reload
        if (isActiveFlexcard) {
        await Promise.resolve();
            this.visiblePanels = { ...this.visiblePanels, [activeTabId]: true };
        }
    }

    @api async reloadCurrentTabContent() {
        const activeTabId      = this._activeTabId;
        const tmpVisiblePanels = { ...this.visiblePanels };
        this.visiblePanels     = { ...this.visiblePanels, [activeTabId]: false };
        await Promise.resolve();
        this.visiblePanels     = tmpVisiblePanels;
    }

    // ─── Internal state ───────────────────────────────────────────────────────

    _tabsInitialized         = false;
    _resizeObserver          = null;
    _lastNavWidth            = 0;
    _isRecalculating         = false;
    _activeTabId             = TABS_CONFIG[0].id;
    _isEditing               = false;
    _showPendingChangesModal = false;
    _pendingTabLink          = null;
    _pendingActivation       = false;
    _needsOverflowRecalc     = false;
    _fieldHiddenTabIds       = [];
    hiddenTabIds             = [];

    // All tabs load immediately so their content (and warning checks) run on init
    visiblePanels = TABS_CONFIG.reduce((acc, tab) => { acc[tab.id] = true; return acc; }, {});

    get showPendingChangesModal() { return this._showPendingChangesModal; }

    // TODO: for now this returns true if ANY tab has a pending Passport warning,
    // regardless of whether that tab is actually overflowed into the "More" menu.
    get hasAnyTabWarning() {
        return Object.values(this.tabWarningState).some(Boolean);
    }

    get overflowTabs() {
        return this.hiddenTabIds.map(id => {
            const cfg = TABS_CONFIG.find(t => t.id === id);
            return {
                id,
                label     : cfg?.label ?? id,
                hasWarning: !!this.tabWarningState[id]
            };
        });
    }

    // Called when a child tab component (e.g. dmt_opp_info) reports whether it
    // currently has a pending Passport warning, after checking its own fields.
    handleOpportunityInfoWarningChange(event) {
        const hasWarning = !!event.detail?.hasWarning;
        if (this.tabWarningState.opportunityInfo === hasWarning) return;
        this.tabWarningState = { ...this.tabWarningState, opportunityInfo: hasWarning };
    }

    handleClientWarningChange(event) {
        const hasWarning = !!event.detail?.hasWarning;
        if (this.tabWarningState.client === hasWarning) return;
        this.tabWarningState = { ...this.tabWarningState, client: hasWarning };
    }

    get tabsConfig() {
        return TABS_CONFIG
            .filter(tab => !this._fieldHiddenTabIds.includes(tab.id))
            .map(tab => {
                const isActive = tab.id === this._activeTabId;
                return {
                    id          : tab.id,
                    label       : tab.label,
                    itemClass   : isActive ? 'slds-tabs_default__item slds-is-active' : 'slds-tabs_default__item',
                    ariaSelected: isActive ? 'true'  : 'false',
                    tabIndex    : isActive ? '0'     : '-1',
                    hasWarning  : !!this.tabWarningState[tab.id]
                };
            });
    }

    // ─── Lifecycle ────────────────────────────────────────────────────────────

    renderedCallback() {
        if (this._tabsInitialized) {
            // Re-activate the current tab after re-render if it's not the default,
            // or if a pending activation was triggered (e.g. active tab was hidden)
            if (this._pendingActivation || this._activeTabId !== TABS_CONFIG[0].id) {
                const link = this.template.querySelector(
                    `.slds-tabs_default__link[data-controls="${this._activeTabId}"]`
                );
                if (link) this._activateTab(link);
                this._pendingActivation = false;
            }
            // Recalculate overflow synchronously (before browser paint) when tab
            // count changed, to avoid a visible flash of all tabs
            if (this._needsOverflowRecalc) {
                this._needsOverflowRecalc = false;
                this._recalcOverflow();
            }
            return;
        }
        this._tabsInitialized = true;
        this._initTabs();
    }

    disconnectedCallback() {
        this._resizeObserver?.disconnect();
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state?.recordId
                         || currentPageReference.state?.c__recordId
                         || currentPageReference.attributes?.recordId;
            this.oppId = this.recordId;
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: [PRODUCT_AREA_FIELD] })
    wiredOpportunity({ error, data }) {
        console.log('Datos wiredOpportunity', JSON.stringify(data));
        if (data) {
            const productArea    = data.fields.DMT_Product_Area__c?.value;
            const newFieldHidden = (!productArea || productArea === 'GTB')? [...GTB_HIDDEN_TABS] : [];


            // Si la tab activa va a ocultarse por cambio de campo, redirigir
            if (newFieldHidden.includes(this._activeTabId) && !this._fieldHiddenTabIds.includes(this._activeTabId)) {
                const firstVisible = TABS_CONFIG.find(t => !newFieldHidden.includes(t.id));
                if (firstVisible) {
                    this._activeTabId       = firstVisible.id;
                    this._pendingActivation = true;
                }
            }

            this._fieldHiddenTabIds = newFieldHidden;
            this._needsOverflowRecalc = true;
        } else if (error) {
            this._fieldHiddenTabIds = [];
            this._needsOverflowRecalc = true;
        }
    }

    // ─── Tab initialisation ───────────────────────────────────────────────────

    _initTabs() {
        const nav = this.template.querySelector('.slds-tabs_default__nav');

        // Event delegation on the nav: covers current AND dynamically added tabs.
        // Per-link listeners would miss tabs that appear after a re-render.
        if (nav) {
            nav.addEventListener('click', (e) => {
                const link = e.target.closest('.slds-tabs_default__link');
                if (!link) return;
                e.preventDefault();
                // If editing and switching tabs, show confirmation modal instead of navigating
                if (this._isEditing && this._activeTabId !== link.dataset.controls) {
                    e.stopPropagation();
                    this._pendingTabLink         = link;
                    this._showPendingChangesModal = true;
                    return;
                }
                this._activateTab(link);
            });

            this._resizeObserver = new ResizeObserver(() => {
                if (this._isRecalculating) return;
                const currentWidth = nav.offsetWidth;
                if (Math.abs(currentWidth - this._lastNavWidth) > 20) {
                    this._lastNavWidth = currentWidth;
                    this._recalcOverflow();
                }
            });
            this._resizeObserver.observe(nav);
        }

        const moreBtn  = this.template.querySelector('.slds-tabs_default__overflow-button button');
        const dropdown = this.template.querySelector('.slds-dropdown-trigger_click');
        if (moreBtn && dropdown) {
            moreBtn.addEventListener('click', (e) => {
                e.stopPropagation();
                dropdown.classList.toggle('slds-is-open');
            });
            this.template.addEventListener('click', (e) => {
                if (!dropdown.contains(e.target)) dropdown.classList.remove('slds-is-open');
            });
        }

        // Panels start hidden (slds-hide) in the markup; explicitly activate the
        // default tab here since _activateTab is otherwise only triggered by clicks.
        const defaultLink = this.template.querySelector(
            `.slds-tabs_default__link[data-controls="${this._activeTabId}"]`
        );
        if (defaultLink) this._activateTab(defaultLink);

        this._recalcOverflow();
    }

    _activateTab(clickedLink) {
        const root = this.template.querySelector('.slds-tabs_default');

        root.querySelectorAll('.slds-tabs_default__item').forEach(li => li.classList.remove('slds-is-active'));
        root.querySelectorAll('.slds-tabs_default__link').forEach(a => {
            a.setAttribute('aria-selected', 'false');
            a.setAttribute('tabindex', '-1');
        });
        root.querySelectorAll('.slds-tabs_default__content').forEach(panel => {
            panel.classList.remove('slds-show');
            panel.classList.add('slds-hide');
        });

        clickedLink.setAttribute('aria-selected', 'true');
        clickedLink.setAttribute('tabindex', '0');
        clickedLink.closest('.slds-tabs_default__item').classList.add('slds-is-active');

        const panelId = clickedLink.dataset.controls;
        const panel   = root.querySelector(`[data-panel-id="${panelId}"]`);
        if (panel) {
            panel.classList.remove('slds-hide');
            panel.classList.add('slds-show');
        }

        this._activeTabId = panelId;

        // Lazy-load: render content on first visit and keep it in the DOM
        if (!this.visiblePanels[panelId]) {
            this.visiblePanels = { ...this.visiblePanels, [panelId]: true };
        }

        const overflowLi = this.template.querySelector('.slds-tabs_default__overflow-button');
        if (overflowLi) overflowLi.classList.remove('slds-is-active');
        const trigger = this.template.querySelector('.slds-dropdown-trigger_click');
        if (trigger) trigger.classList.remove('slds-is-open');
    }

    // ─── Overflow recalculation ───────────────────────────────────────────────

    _recalcOverflow() {
        this._isRecalculating = true;

        const nav     = this.template.querySelector('.slds-tabs_default__nav');
        const moreItem= this.template.querySelector('.slds-tabs_default__overflow-button');
        const allTabs = [...this.template.querySelectorAll('[data-tab-item]')];

        if (!nav || !moreItem) {
            this._isRecalculating = false;
            return;
        }

        allTabs.forEach(li => li.classList.remove('slds-hide'));
        moreItem.classList.add('slds-hide');
        this.hiddenTabIds = [];

        const navWidth  = nav.offsetWidth;
        const moreWidth = moreItem.offsetWidth || 80;
        const tabMargin = allTabs.length > 0
            ? parseFloat(getComputedStyle(allTabs[0]).marginRight) +
              parseFloat(getComputedStyle(allTabs[0]).marginLeft)
            : 4;

        const hiddenSet = new Set();
        let usedWidth   = moreWidth;
        for (const li of allTabs) {
            usedWidth += li.offsetWidth + tabMargin;
            if (usedWidth > navWidth) hiddenSet.add(li);
        }

        if (hiddenSet.size === 0) {
            this._lastNavWidth    = nav.offsetWidth;
            this._isRecalculating = false;
            return;
        }

        // If active tab overflows, swap it with the last visible tab
        const activeTab = allTabs.find(li => li.classList.contains('slds-is-active'));
        if (activeTab && hiddenSet.has(activeTab)) {
            hiddenSet.delete(activeTab);
            const visibles = allTabs.filter(t => !hiddenSet.has(t) && t !== activeTab);
            if (visibles.length > 0) hiddenSet.add(visibles[visibles.length - 1]);
        }

        // Keep hiding from the right until everything fits
        let loops = 0;
        while (loops < allTabs.length) {
            loops++;
            const visibleNow = allTabs.filter(t => !hiddenSet.has(t));
            let totalWidth   = moreWidth;
            for (const li of visibleNow) totalWidth += li.offsetWidth + tabMargin;
            if (totalWidth <= navWidth) break;
            const candidate = [...visibleNow].reverse().find(t => t !== activeTab);
            if (!candidate) break;
            hiddenSet.add(candidate);
        }

        moreItem.classList.remove('slds-hide');
        const hiddenLis = allTabs.filter(t => hiddenSet.has(t));
        hiddenLis.forEach(li => li.classList.add('slds-hide'));
        this.hiddenTabIds = hiddenLis.map(li => li.querySelector('[data-controls]')?.dataset.controls).filter(Boolean);

        const activeIsHidden = activeTab && hiddenSet.has(activeTab);
        moreItem.classList.toggle('slds-is-active', !!activeIsHidden);

        // Post-render safety: hide more tabs if DOM still overflows
        requestAnimationFrame(() => {
            let postLoops = 0;
            const extraIds = [];
            while (nav.scrollWidth > nav.clientWidth && postLoops < allTabs.length) {
                postLoops++;
                const stillVisible = allTabs.filter(t => !t.classList.contains('slds-hide'));
                const extra        = [...stillVisible].reverse().find(t => t !== activeTab);
                if (!extra) break;
                extra.classList.add('slds-hide');
                const extraId = extra.querySelector('[data-controls]')?.dataset.controls;
                if (extraId) extraIds.push(extraId);
            }
            if (extraIds.length > 0) {
                this.hiddenTabIds = [...this.hiddenTabIds, ...extraIds];
            }
        });

        this._lastNavWidth    = nav.offsetWidth;
        this._isRecalculating = false;
    }

    handleDropdownItemClick(event) {
        event.preventDefault();
        const tabId = event.currentTarget.dataset.tabId;
        const link  = this.template.querySelector(`.slds-tabs_default__link[data-controls="${tabId}"]`);
        if (!link) return;

        if (this._isEditing && this._activeTabId !== tabId) {
            this._pendingTabLink         = link;
            this._showPendingChangesModal = true;
            return;
        }

        const trigger = this.template.querySelector('.slds-dropdown-trigger_click');
        if (trigger) trigger.classList.remove('slds-is-open');
        this._activateTab(link);
        this._recalcOverflow();
    }

    // ─── Pending changes modal ────────────────────────────────────────────────

    async handleExitWithoutSaving() {
        this.dispatchEvent(new CustomEvent('reloadeditmode', { bubbles: true, composed: true }));
        if (this._pendingTabLink) {
            this._activateTab(this._pendingTabLink);
            this._pendingTabLink = null;
        }
        this._showPendingChangesModal = false;
    }

    handleCloseModal() {
        this._showPendingChangesModal = false;
        this._pendingTabLink          = null;
    }

    handleProductDeleted() {
        const updated = {};
        TABS_CONFIG.forEach(tab => {
            updated[tab.id] = tab.id === this._activeTabId ? this.visiblePanels[tab.id] : false;
        });
        this.visiblePanels = updated;
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    _hasPermissionChanged(newPermissions) {
        return JSON.stringify(newPermissions) !== JSON.stringify(this._permissionUserRecord);
    }

    _isTabEditable(tabId) {
        if (!this._permissionsReceived || !this._stageReceived) return false;
        if (this._stageRecord === 'Approval' && !!(this._permissionUserRecord?.isTeamMemberApprovalEdit)) {
            if (TEAM_MEMBER_APPROVAL_EDIT_TABS.includes('ALL')) return true;
            return !!tabId && TEAM_MEMBER_APPROVAL_EDIT_TABS.includes(tabId);
        }
        if (!this._permissionUserRecord?.accessLevel_edit) return false;

        const tabConfig      = tabId ? TABS_CONFIG.find(t => t.id === tabId) : null;
        const editableStages = tabConfig?.editableStages ?? new Set();
        return editableStages.has('ALL') || editableStages.has(this._stageRecord);
    }
}