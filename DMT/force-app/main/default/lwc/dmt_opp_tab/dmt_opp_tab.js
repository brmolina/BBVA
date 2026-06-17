import { LightningElement, wire, api } from 'lwc';
import { CurrentPageReference }        from 'lightning/navigation';
import DMT_LABEL_MODAL_UNSAVED_CHANGES_TITLE from '@salesforce/label/c.DMT_Label_Modal_Unsaved_Changes_Title';
import DMT_LABEL_MODAL_UNSAVED_CHANGES_BODY  from '@salesforce/label/c.DMT_Label_Modal_Unsaved_Changes_Body';
import DMT_LABEL_BTN_EXIT_WITHOUT_SAVING     from '@salesforce/label/c.DMT_Label_Btn_Exit_Without_Saving';
import DMT_LABEL_BTN_KEEP_EDITING            from '@salesforce/label/c.DMT_Label_Btn_Keep_Editing';

const TABS_CONFIG = [
    { id: 'opportunityInfo',      label: 'Opportunity Info' },
    { id: 'client',               label: 'Client' },
    { id: 'clientV2',             label: 'Client V2' },
    { id: 'products',             label: 'Products' },
    { id: 'approvalProcessData',  label: 'Approval Process Data' },
    { id: 'commercialProcessData',label: 'Commercial Process Data' },
    { id: 'underwriting',         label: 'Underwriting' },
    { id: 'participants',         label: 'Participants' },
    { id: 'versions',             label: 'Versions' }
];

// Stages that allow editing (subject to user permissions)
const EDITABLE_STAGES = new Set(['Draft', 'Ready to close']);

export default class Dmt_opp_tab extends LightningElement {

    recordId;
    isLoading = false;

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
    // so that canEdit never momentarily returns true during initialisation
    @api get canEdit() {
        if (!this._permissionsReceived || !this._stageReceived) return false;
        if (this._stageRecord === 'Approval' && !!(this._permissionUserRecord?.isTeamMemberApprovalEdit)) return true;
        return EDITABLE_STAGES.has(this._stageRecord) && !!(this._permissionUserRecord?.accessLevel_edit);
    }

    @api set isEditing(value) { this._isEditing = value; }
    get isEditing()            { return this._isEditing; }

    @api async reloadAllTabsContent() {
        const activeTabId       = this._activeTabId;
        const tmpVisiblePanels  = { ...this.visiblePanels };
        this.visiblePanels = Object.fromEntries(
            Object.keys(this.visiblePanels).map(key => [key, key === activeTabId ? tmpVisiblePanels[key] : false])
        );
        await Promise.resolve();
        this.visiblePanels = tmpVisiblePanels;
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

    // All panels start visible; toggled by reloadAllTabsContent / reloadCurrentTabContent
    visiblePanels = TABS_CONFIG.reduce((acc, tab) => { acc[tab.id] = true; return acc; }, {});

    get showPendingChangesModal() { return this._showPendingChangesModal; }

    get tabsConfig() {
        return TABS_CONFIG.map(tab => {
            const isActive = tab.id === this._activeTabId;
            return {
                id          : tab.id,
                label       : tab.label,
                itemClass   : isActive ? 'slds-tabs_default__item slds-is-active' : 'slds-tabs_default__item',
                ariaSelected: isActive ? 'true'  : 'false',
                tabIndex    : isActive ? '0'     : '-1'
            };
        });
    }

    // ─── Lifecycle ────────────────────────────────────────────────────────────

    renderedCallback() {
        if (this._tabsInitialized) {
            // Re-activate the current tab after re-render if it's not the default
            if (this._activeTabId !== TABS_CONFIG[0].id) {
                const link = this.template.querySelector(
                    `.slds-tabs_default__link[data-controls="${this._activeTabId}"]`
                );
                if (link) this._activateTab(link);
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

    // ─── Tab initialisation ───────────────────────────────────────────────────

    _initTabs() {
        this.template.querySelectorAll('.slds-tabs_default__link').forEach(link => {
            link.addEventListener('click', (e) => {
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
        });

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

        const nav = this.template.querySelector('.slds-tabs_default__nav');
        if (nav) {
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
        const moreList= this.template.querySelector('.slds-dropdown__list');
        const allTabs = [...this.template.querySelectorAll('[data-tab-item]')];

        if (!nav || !moreItem || !moreList) {
            this._isRecalculating = false;
            return;
        }

        allTabs.forEach(li => li.classList.remove('slds-hide'));
        moreItem.classList.add('slds-hide');
        moreList.innerHTML = '';

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
        allTabs.filter(t => hiddenSet.has(t)).forEach(li => {
            li.classList.add('slds-hide');
            this._addDropdownItem(moreList, li);
        });

        const activeIsHidden = activeTab && hiddenSet.has(activeTab);
        moreItem.classList.toggle('slds-is-active', !!activeIsHidden);

        // Post-render safety: hide more tabs if DOM still overflows
        requestAnimationFrame(() => {
            let postLoops = 0;
            while (nav.scrollWidth > nav.clientWidth && postLoops < allTabs.length) {
                postLoops++;
                const stillVisible = allTabs.filter(t => !t.classList.contains('slds-hide'));
                const extra        = [...stillVisible].reverse().find(t => t !== activeTab);
                if (!extra) break;
                extra.classList.add('slds-hide');
                this._addDropdownItem(moreList, extra);
            }
        });

        this._lastNavWidth    = nav.offsetWidth;
        this._isRecalculating = false;
    }

    _addDropdownItem(moreList, tabLi) {
        const link     = tabLi.querySelector('.slds-tabs_default__link');
        const label    = link?.textContent?.trim();
        const menuItem = document.createElement('li');
        menuItem.className = 'slds-dropdown__item';
        menuItem.setAttribute('role', 'presentation');
        menuItem.innerHTML = `<a href="#" role="menuitem" tabindex="-1" style="text-transform:uppercase"><span>${label}</span></a>`;
        menuItem.querySelector('a').addEventListener('click', (e) => {
            e.preventDefault();
            if (this._isEditing && this._activeTabId !== link.dataset.controls) {
                e.stopPropagation();
                this._pendingTabLink         = link;
                this._showPendingChangesModal = true;
                return;
            }
            this.template.querySelector('.slds-dropdown-trigger_click').classList.remove('slds-is-open');
            if (link) this._activateTab(link);
            this._recalcOverflow();
        });
        moreList.appendChild(menuItem);
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

    // ─── Helpers ──────────────────────────────────────────────────────────────

    _hasPermissionChanged(newPermissions) {
        return JSON.stringify(newPermissions) !== JSON.stringify(this._permissionUserRecord);
    }
}