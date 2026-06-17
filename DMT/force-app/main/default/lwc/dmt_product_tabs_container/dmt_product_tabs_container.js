import { LightningElement, api } from 'lwc';

export default class dmt_product_tabs_container extends LightningElement {

    // ── Public API ──────────────────────────────────────────
    // config: a single configuration object that carries everything the
    // tabs component needs, so the parent can hand over data + schema atomically.
    //   {
    //     nameField:     'DES_Product_Name__c',  // required
    //     amountField:   'Total_Amount__c',      // required
    //     currencyField: 'CurrencyIsoCode',      // optional
    //     products:      [ ...raw records ]      // required, must contain Id
    //   }
    _config = null;
    _activeTabId = null;

    @api
    set config(value) {
        const newConfig = value || null;
        const oldProducts = this._config?.products || [];
        const newProducts = newConfig?.products || [];

        const idsChanged = this._productIdsDiffer(oldProducts, newProducts);
        const fieldsChanged =
            this._config?.nameField !== newConfig?.nameField
            || this._config?.amountField !== newConfig?.amountField
            || this._config?.currencyField !== newConfig?.currencyField;

        this._config = newConfig;

        // Resync active tab against the new product list
        const stillExists = this._activeTabId
            && newProducts.some(p => p.Id === this._activeTabId);
        if (!stillExists) {
            this._activeTabId = newProducts.length > 0 ? newProducts[0].Id : null;
        }

        // If anything that affects the rendered tabs has changed, force re-init
        if (idsChanged || fieldsChanged) {
            this._tabsInitialized = false;
        }
    }
    get config() {
        return this._config;
    }

    @api
    set activeTabId(value) {
        if (value && value !== this._activeTabId) {
            this._activeTabId = value;
            // If tabs are already on the DOM, reflect the change visually
            if (this._tabsInitialized) {
                const link = this.template.querySelector(
                    `.slds-tabs_scoped__link[data-controls="${value}"]`
                );
                if (link) this._activateTab(link, /* silent */ true);
            }
        }
    }
    get activeTabId() {
        return this._activeTabId;
    }

    // ── Internal tab system state ──────────────────────────
    _tabsInitialized = false;
    _resizeObserver = null;
    _lastNavWidth = 0;
    _isRecalculating = false;


    _listenersController = null;
    dropdownItems = [];

    _scrollPositions = new Map();


    get isReady() {
        if (!this._config) return false;
        const { nameField, amountField, products } = this._config;
        return Array.isArray(products)
            && products.length > 0
            && !!nameField
            && !!amountField;
    }


    _safeRead(record, fieldName) {
        if (!record || !fieldName) return '';
        const value = record[fieldName];
        if (value === null || value === undefined) return '';
        return String(value);
    }

 
    _buildAmountLabel(record) {
        const cfg = this._config;
        const rawAmount = this._safeRead(record, cfg.amountField);
        const amount = rawAmount !== '' ? rawAmount : '0';
        const currency = this._safeRead(record, cfg.currencyField);
        return currency ? `${amount} ${currency}` : amount;
    }

    /**
     * Computed list of tabs for the template.
     * Includes the SLDS ids (link + panel) plus the css classes / aria
     * attributes that depend on whether the tab is the active one.
     */
    get tabsConfig() {
        if (!this.isReady) return [];
        const cfg = this._config;
        return cfg.products.map(p => {
            const isActive = p.Id === this._activeTabId;
            return {
                id: p.Id,
                label: this._safeRead(p, cfg.nameField),
                amount: this._buildAmountLabel(p),
                linkId: `tab-product-${p.Id}__item`,
                panelId: `tab-product-${p.Id}`,
                isActive,
                itemClass: isActive
                    ? 'slds-tabs_scoped__item slds-is-active'
                    : 'slds-tabs_scoped__item',
                panelClass: isActive
                    ? 'slds-tabs_scoped__content slds-show'
                    : 'slds-tabs_scoped__content slds-hide',
                ariaSelected: isActive ? 'true' : 'false',
                tabIndex: isActive ? '0' : '-1'
            };
        });
    }

    // ══════════════════════════════════════════════════════════════
    // LIFECYCLE
    // ══════════════════════════════════════════════════════════════

    renderedCallback() {
        if (this._tabsInitialized) return;
        if (!this.isReady) return;

        const nav = this.template.querySelector('.slds-tabs_scoped__nav');
        if (!nav) return;

        this._tabsInitialized = true;
        this._initTabs();
    }

    disconnectedCallback() {
        // Tear down everything when the component is removed from the DOM
        this._resizeObserver?.disconnect();
        this._listenersController?.abort();
    }


    _initTabs() {

        this._listenersController?.abort();
        this._listenersController = new AbortController();
        const { signal } = this._listenersController;

        // Disconnect any previous observer to avoid duplicates after a re-init
        this._resizeObserver?.disconnect();
        this._resizeObserver = null;

        // --- 1. Tab click handlers ---
        this.template.querySelectorAll('.slds-tabs_scoped__link').forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                this._activateTab(link);
            }, { signal });
        });

        // --- 2. "More" dropdown setup ---
        const moreBtn = this.template.querySelector('.slds-tabs_scoped__overflow-button button');
        const dropdown = this.template.querySelector('.slds-dropdown-trigger_click');
        if (moreBtn && dropdown) {
            moreBtn.addEventListener('click', (e) => {
                e.stopPropagation();
                dropdown.classList.toggle('slds-is-open');
            }, { signal });

            this.template.addEventListener('click', (e) => {
                if (!dropdown.contains(e.target)) {
                    dropdown.classList.remove('slds-is-open');
                }
            }, { signal });
        }

        // --- 3. Responsive overflow observer ---
        const nav = this.template.querySelector('.slds-tabs_scoped__nav');
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

        // First overflow calculation
        this._recalcOverflow();
    }

    /**
     * Activate a specific tab visually and (unless silent) notify the parent.
     */
    _activateTab(clickedLink, silent = false) {
        const root = this.template.querySelector('.slds-tabs_scoped');

        // Save scroll position of the currently active panel before hiding it
        const currentActivePanel = root.querySelector('.slds-tabs_scoped__content.slds-show');
        if (currentActivePanel) {
            const currentTabId = currentActivePanel.dataset.panelId;
            const scrollableContent = currentActivePanel.querySelector('.slds-tabs_scoped__content')
                || currentActivePanel;
            if (scrollableContent) {
                this._scrollPositions.set(currentTabId, scrollableContent.scrollTop);
            }
        }

        // Deactivate all tabs
        root.querySelectorAll('.slds-tabs_scoped__item')
            .forEach(li => li.classList.remove('slds-is-active'));
        root.querySelectorAll('.slds-tabs_scoped__link').forEach(a => {
            a.setAttribute('aria-selected', 'false');
            a.setAttribute('tabindex', '-1');
        });

        // Hide all panels
        root.querySelectorAll('.slds-tabs_scoped__content').forEach(panel => {
            panel.classList.remove('slds-show');
            panel.classList.add('slds-hide');
        });

        // Activate the clicked tab
        clickedLink.setAttribute('aria-selected', 'true');
        clickedLink.setAttribute('tabindex', '0');
        clickedLink.closest('.slds-tabs_scoped__item').classList.add('slds-is-active');

        // Show the matching panel
        const tabId = clickedLink.dataset.controls;
        const panel = root.querySelector(`[data-panel-id="${tabId}"]`);
        if (panel) {
            panel.classList.remove('slds-hide');
            panel.classList.add('slds-show');

            // Restore scroll position for the newly activated panel
            requestAnimationFrame(() => {
                const savedScroll = this._scrollPositions.get(tabId);
                if (savedScroll !== undefined && savedScroll > 0) {
                    panel.scrollTop = savedScroll;
                }
            });
        }

        this._activeTabId = tabId;

        const overflowLi = this.template.querySelector('.slds-tabs_scoped__overflow-button');
        if (overflowLi) overflowLi.classList.remove('slds-is-active');
        const trigger = this.template.querySelector('.slds-dropdown-trigger_click');
        if (trigger) trigger.classList.remove('slds-is-open');

        if (!silent) {
            this.dispatchEvent(new CustomEvent('tabchange', {
                detail: { tabId },
                bubbles: true,
                composed: true
            }));
        }
    }

    /**
     * Recalculate which tabs overflow the navigation bar:
     *  1. Show all tabs temporarily to measure their widths
     *  2. Walk left-to-right; mark tabs that exceed available width
     *  3. If the active tab overflows, swap it with the last visible tab
     *  4. Hide overflowing tabs and populate the "More" dropdown
     *  5. Post-render safety check for any remaining overflow
     */
    _recalcOverflow() {
        this._isRecalculating = true;

        const nav = this.template.querySelector('.slds-tabs_scoped__nav');
        const moreItem = this.template.querySelector('.slds-tabs_scoped__overflow-button');
        const allTabs = [...this.template.querySelectorAll('[data-tab-item]')];

        if (!nav || !moreItem) {
            this._isRecalculating = false;
            return;
        }

        // Reset state before measuring
        allTabs.forEach(li => li.classList.remove('slds-hide'));
        moreItem.classList.add('slds-hide');
        // Clear the dropdown list (will be repopulated below if needed)
        this.dropdownItems = [];

        const navWidth = nav.offsetWidth;
        const moreWidth = moreItem.offsetWidth || 80;
        const tabMargin = allTabs.length > 0
            ? parseFloat(getComputedStyle(allTabs[0]).marginRight)
              + parseFloat(getComputedStyle(allTabs[0]).marginLeft)
            : 4;

        const hiddenSet = new Set();

        // First pass: determine which tabs exceed the available width
        let usedWidth = moreWidth;
        for (const li of allTabs) {
            usedWidth += li.offsetWidth + tabMargin;
            if (usedWidth > navWidth) hiddenSet.add(li);
        }

        // All tabs fit — no overflow needed
        if (hiddenSet.size === 0) {
            this._lastNavWidth = nav.offsetWidth;
            this._isRecalculating = false;
            return;
        }

        // If the active tab ended up in overflow, swap it back and hide the last visible tab instead
        const activeTab = allTabs.find(li => li.classList.contains('slds-is-active'));
        if (activeTab && hiddenSet.has(activeTab)) {
            hiddenSet.delete(activeTab);
            const visibles = allTabs.filter(t => !hiddenSet.has(t) && t !== activeTab);
            if (visibles.length > 0) {
                hiddenSet.add(visibles[visibles.length - 1]);
            }
        }

        // Keep hiding tabs from the right until everything fits
        let loops = 0;
        while (loops < allTabs.length) {
            loops++;
            const visibleNow = allTabs.filter(t => !hiddenSet.has(t));
            let totalWidth = moreWidth;
            for (const li of visibleNow) {
                totalWidth += li.offsetWidth + tabMargin;
            }
            if (totalWidth <= navWidth) break;
            const candidate = [...visibleNow].reverse().find(t => t !== activeTab);
            if (!candidate) break;
            hiddenSet.add(candidate);
        }

        // Apply slds-hide to overflowing tabs
        allTabs.filter(t => hiddenSet.has(t)).forEach(li => li.classList.add('slds-hide'));

        // Show the "More" button
        moreItem.classList.remove('slds-hide');

        // Mark "More" as active if the currently active tab is in the overflow
        const activeIsHidden = activeTab && hiddenSet.has(activeTab);
        moreItem.classList.toggle('slds-is-active', !!activeIsHidden);

        // Post-render safety check: if the DOM still overflows, hide more tabs
        requestAnimationFrame(() => {
            let postLoops = 0;
            while (nav.scrollWidth > nav.clientWidth && postLoops < allTabs.length) {
                postLoops++;
                const stillVisible = allTabs.filter(t => !t.classList.contains('slds-hide'));
                const extra = [...stillVisible].reverse().find(t => t !== activeTab);
                if (!extra) break;
                extra.classList.add('slds-hide');
                hiddenSet.add(extra);
            }
            // Build the reactive dropdown list from the final set of hidden tabs,
            // preserving the original tab order so items appear sorted.
            this.dropdownItems = allTabs
                .filter(t => hiddenSet.has(t))
                .map(li => this._dropdownItemFromTab(li))
                .filter(Boolean);
        });

        this._lastNavWidth = nav.offsetWidth;
        this._isRecalculating = false;
    }

    /**
     * Build a dropdown item descriptor from a hidden tab <li>.
     * Returns { id, label, amount } so it can be rendered declaratively
     * by the for:each in the template (no manual DOM manipulation needed).
     */
    _dropdownItemFromTab(tabLi) {
        const link = tabLi.querySelector('.slds-tabs_scoped__link');
        if (!link) return null;
        const id = link.dataset.controls;
        const nameEl = tabLi.querySelector('.tab-product-name');
        const amountEl = tabLi.querySelector('.tab-product-amount');
        const label = nameEl?.textContent?.trim() || link.textContent?.trim() || '';
        const amount = amountEl?.textContent?.trim() || '';
        return { id, label, amount };
    }

    /**
     * Click handler for items inside the "More" dropdown.
     * Wired declaratively from the template (data-tab-id identifies the target tab).
     */
    handleDropdownItemClick(event) {
        event.preventDefault();
        const tabId = event.currentTarget.dataset.tabId;

        // Close the dropdown
        const trigger = this.template.querySelector('.slds-dropdown-trigger_click');
        if (trigger) trigger.classList.remove('slds-is-open');

        // Activate the matching tab and recalculate overflow
        const link = this.template.querySelector(
            `.slds-tabs_scoped__link[data-controls="${tabId}"]`
        );
        if (link) this._activateTab(link);
        this._recalcOverflow();
    }

    /** Helper: detect whether the set of product ids has changed between two lists */
    _productIdsDiffer(oldList, newList) {
        if (oldList.length !== newList.length) return true;
        for (let i = 0; i < oldList.length; i++) {
            if (oldList[i].Id !== newList[i].Id) return true;
        }
        return false;
    }
}