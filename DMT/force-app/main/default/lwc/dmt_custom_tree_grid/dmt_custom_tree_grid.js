import { LightningElement, track, api } from 'lwc';
import DMT_No_Records from '@salesforce/label/c.DMT_No_Records';

export default class Dmt_custom_tree_grid extends LightningElement {

    @api columns;
    @api columnsParent;
    @api columnsChildren;
    @track processedData;
    @track processedFilters;
    @track processedDataForSearch = [];
    @track isDataProcessed = false;
    @track areFiltersLoaded = false;
    @track notEmpty = false;
    @api regularView;
    @api filters;
    @api search;
    @api isExpanded = false;
    @api headerTitle;
    // DESARROLLO ACCIONES MASIVAS
    _isSelectionMode = false;
    isSelectAllActive = false;
    @track selectedRows = [];
    selectedFilters = {};
    _modelData;
    _isVisible = true;
    _lastAppliedMaxH = null;
    _io = null;
    _resizeTimer = null;
    _resizeBound = false;
    _roBound = false;
    _observer;
    @track columnWidths = {};

    minColumnWidth = 45;
    isResizingColumn = false;
    resizingField = null;
    startX = 0;
    startWidth = 0;
    boundResizeMove = null;
    boundResizeEnd = null;

    labels = {
        DMT_No_Records
    };

    get columnsCount() {
        const baseColumns = this.columns?.length || 1;
        return this.isSelectionMode ? baseColumns + 1 : baseColumns;
    }

    get tableClass() {
        const base = 'slds-table slds-table--bordered slds-box slds-max-medium-table--stacked-horizontal custom-table full-width-table';
        return Object.keys(this.columnWidths || {}).length > 0 ? `${base} resizable-active` : base;
    }

    get columnsWithResize() {
        return (this.columns || []).map(col => {
            const width = this.columnWidths[col.fieldName];
            return {
                ...col,
                widthStyle: width ? `width: ${width}px; min-width: ${width}px;` : '',
                sortIconClass: col.sortDirection === 'asc'
                ? 'sort-icon sort-icon-asc'
                : 'sort-icon'
            };
        });
    }

    @api
    get isSelectionMode() {
        return this._isSelectionMode;
    }

    set isSelectionMode(value) {
        const nextValue = Boolean(value);
        const previousValue = this._isSelectionMode;
        this._isSelectionMode = nextValue;

        if (previousValue && !nextValue) {
            this.isSelectAllActive = false;
            this.selectedRows = [];
            this.emitSelectionChange();
        }
    }

    get visibleSelectableRowKeys() {
        return (this.processedData || []).map(item => item.itemKey);
    }

    get areAllVisibleRowsSelected() {
        const visibleKeys = this.visibleSelectableRowKeys;
        if (visibleKeys.length === 0) {
            return false;
        }
        return visibleKeys.every(key => this.selectedRows.includes(key));
    }

    get isSelectAllDisabled() {
        return this.visibleSelectableRowKeys.length === 0;
    }

    @api
    get modelData() {
        return this._modelData;
    }
    set modelData(value) {
        this._modelData = value;
        if (value && this.columns) {
            this.processedDataForSearch = [];
            this.processData();
        }
    }

    get containerClass() {
        const base = 'slds-tree_container full-width-container slds-grid';
        return this.notEmpty ? base : `${base} empty-mode`;
    }

    /**
     * Opened at launch
     */
    connectedCallback() {
        this.boundResizeMove = this.handleColumnResizeMove.bind(this);
        this.boundResizeEnd = this.handleColumnResizeEnd.bind(this);

        if (this._modelData && this.columns) {
            this.processData();
        }
        const el = document.querySelector('.lwcAppFlexipage');
        if (el) el.classList.add('dmt-case-tasks-active');
    }

    renderedCallback() {
        if (this.notEmpty && !this._observer) {
            this.setupIntersectionObserver();
        }
    }

    disconnectedCallback() {
        this.removeColumnResizeListeners();

        if (this._observer) {
            this._observer.disconnect();
        }
        const el = document.querySelector('.oneContent.active.lafPageHost');
        if (el) el.classList.remove('dmt-case-tasks-active');
    }


    setupIntersectionObserver() {
        const sentinel = this.refs.scrollSentinel;

        if (!sentinel) return;

        const options = {
            root: this.template.querySelector('.table-scroller'),
            rootMargin: '100px',
            threshold: 0.1
        };

        this._observer = new IntersectionObserver((entries) => {
            const entry = entries[0];
            if (entry.isIntersecting) {
                this.dispatchEvent(new CustomEvent('loadmoredata'));
            }
        }, options);

        this._observer.observe(sentinel);
    }

    processData() {
        const processNode = (item, depth, parentItemKey) => {
            let itemAux = {};
            let newParentItemKey;
            itemAux.originalItem = JSON.parse(JSON.stringify(item));
            if (item.hasOwnProperty('sameAsSubItems') && item.sameAsSubItems == true) {
                const rowCells = this.columns.map(col => ({
                    fieldName: col.fieldName,
                    fieldNameLabel: col.label,
                    value: item[col.fieldName] ? item[col.fieldName] : '',
                    isUrl: col.type == 'url' ? true : false,
                    isModal: col.type == 'url' && item[col.fieldName].urlValue && item[col.fieldName].urlValue.startsWith('c-') ? true : false,
                    urlLabel: col.type == 'url' ? item[col.fieldName].urlLabel : '',
                    urlValue: col.type == 'url' ? item[col.fieldName].urlValue : '',
                    caseDescription: item.caseDescription ? item.caseDescription : ''
                }));
                itemAux.isStandardView = true;
                itemAux.cells = rowCells;
            } else {
                itemAux.isStandardView = false;
            }
            itemAux.itemKey = item.itemKey;
            itemAux.itemLabel = item.itemLabel;
            itemAux.isParent = ((depth == 0 || (item.subitems && item.subitems.length > 0)) || parentItemKey != item.itemKey);
            let itemCopy = JSON.parse(JSON.stringify(item));
            itemCopy.isParent = itemAux.isParent;
            itemCopy.isStandardView = itemAux.isStandardView;
            if (parentItemKey) {
                itemCopy.parentItemKey = parentItemKey;
                itemAux.parentItemKey = parentItemKey;
            }
            newParentItemKey = item.itemKey;
            delete itemCopy.subitems;
            this.processedDataForSearch.push(itemCopy);
            if (item.subitems && item.subitems.length > 0) {
                itemAux.subitems = item.subitems.map(child => processNode(child, depth + 1, newParentItemKey));
            }
            return {
                ...itemAux,
                expanded: this.isExpanded,
                iconName: this.isExpanded ? 'utility:chevrondown' : 'utility:chevronright'
            }
        };

        this.processedData = (this.modelData || []).map(item => processNode(item, 0, undefined));
        this.notEmpty = this.processedData.length > 0;
        if (this.processedData.length > 0) {
            this.notEmpty = true;
        }
        this.originalProcessedData = [...this.processedData];
        this.syncSelectAllWithVisibleRows();
        if (this.filters && this.filters.length > 0) {
            const filtersFields = this.filters.map(filter => filter.fieldName);
            this.processFilters(filtersFields, this.processedDataForSearch);
        }
        this.isDataProcessed = true;
    }

    /**
     * This method is used to process the filters, setting the possible values through all the options that comes from the parent component
     * @param {*} fieldNameArray
     * @param {*} arrayToFind
     */
    processFilters(fieldNameArray, arrayToFind) {
        let fieldValuesMap = {};
        if (arrayToFind.length > 0) {
            // For each item of the arrayToFind we group all the values of a certain field for the filter in a Set.
        arrayToFind.forEach(item => {
            fieldNameArray.forEach(fieldObj => {
                const fieldName = fieldObj;
                if (!fieldValuesMap[fieldName]) {
                    fieldValuesMap[fieldName] = new Set();
                }
                if (item[fieldName]) {
                    fieldValuesMap[fieldName].add(item[fieldName]);
                }
            });
        });

        // Creating a copy
        this.processedFilters = JSON.parse(JSON.stringify(this.filters));
        // For all the fields we create an array that contains objects with label/value to pass them to the multiselect combo lightning
        this.processedFilters = this.processedFilters.map(key => {
            if (fieldNameArray.includes(key.fieldName)) {
                let possibleValues = [];
                Array.from(fieldValuesMap[key.fieldName]).forEach(val => {
                    let object = {
                        label: val,
                        value: val
                    };
                    possibleValues.push(object);
                })
                key.options = possibleValues;
            } else {
                key.options = [];
            }

            if (!key.value) {
                key.value = '';
            }
            return key;
        });
        }

        //The filters are loaded so we communicate to the html
        this.areFiltersLoaded = true;
    }

    /**
     * Method used to show the subItems
     * @param {*} event
     */
    toggleCase(event) {
        const itemKey = event.currentTarget.dataset.id;
        this.processedData = this.processedData.map(item => {
            if (item.itemKey === itemKey) {
                const isExpanded = !item.expanded;
                return {
                    ...item,
                    expanded: isExpanded,
                    iconName: isExpanded ? 'utility:chevrondown' : 'utility:chevronright'
                };
            }
            return item;
        });
    }

    /**
     * Method used to search within the table, it is called from an event from the databarsearch
     * @param {*} event
     */
    handleSearch(event) {
        const filteredFlatList = event.detail.dataFind;
        if (filteredFlatList.length === 0) {
            this.processedData = [];
            this.isDataProcessed = true;
            this.areFiltersLoaded = false;
            const filtersFields = this.filters.map(filter => filter.fieldName);
            this.processFilters(filtersFields, []);
            return;
        }

        // Helper: returns true if node is in filteredFlatList
        const matchFn = node => filteredFlatList.some(item => item.itemKey === node.itemKey);

        // Recursive tree filter
        function filterTree(nodes, matchFn) {
            return nodes
                .map(node => {
                    let filteredSubitems = node.subitems ? filterTree(node.subitems, matchFn) : [];
                    if (matchFn(node) || filteredSubitems.length > 0) {
                        return {
                            ...node,
                            subitems: filteredSubitems
                        };
                    }
                    return null;
                })
                .filter(Boolean);
        }

        // Filter the original tree structure
        this.processedData = filterTree(this.originalProcessedData, matchFn);
        this.syncSelectAllWithVisibleRows();
        this.isDataProcessed = true;

        // Reload filters with the new processed data
        this.areFiltersLoaded = false;
        const filtersFields = this.filters.map(filter => filter.fieldName);
        this.processFilters(filtersFields, filteredFlatList);
    }

    handlePicklistChange(event) {
        const fieldsFromLWC = event.detail.data;
        const picklistName = event.detail.picklist;

        // Save selected filters
        this.selectedFilters[picklistName] = fieldsFromLWC.map(item => item.value);

        // Reset processedData from original
        const resetData = [...this.originalProcessedData];

        let recordsWithFilter = [];
        let hasAnyFilter = false;

        for (let record of resetData) {
            let parentPasses = true;
            let filtersApplied = 0;

            // Check parent cells against active filters
            for (let cell of record.cells || []) {
                const field = cell.fieldName;
                if (this.selectedFilters[field] && this.selectedFilters[field].length > 0) {
                    filtersApplied++;
                    hasAnyFilter = true;
                    if (!this.selectedFilters[field].includes(cell.value)) {
                        parentPasses = false;
                    }
                }
            }

            if (parentPasses && filtersApplied > 0) {
                // Parent passes all filters
                recordsWithFilter.push(record);
                continue;
            }

            // Check children if parent fails
            const matchingSubitems = (record.subitems || []).filter(subitem => {
                return (subitem.cells || []).every(cell => {
                    const field = cell.fieldName;
                    return !this.selectedFilters[field] || this.selectedFilters[field].includes(cell.value);
                });
            });

            if (matchingSubitems.length > 0) {
                // Only create a new object if children match
                const newRecord = {
                    ...record,
                    subitems: matchingSubitems,
                    expanded: true,
                    iconName: 'utility:chevrondown'
                };
                recordsWithFilter.push(newRecord);
            }
        }

        // Update processedData
        if (hasAnyFilter) {
            this.processedData = [...recordsWithFilter];
        } else {
            // No filters applied, reset to original
            this.processedData = [...resetData];
        }

        this.syncSelectAllWithVisibleRows();

        // Trigger reactive updates
        this.isDataProcessed = false;
        this.isDataProcessed = true;
    }

    handleTableScroll(event) {
    const target = event.target;

        const isNearBottom = target.scrollHeight - target.scrollTop <= target.clientHeight + 100;

        if (isNearBottom) {
            this.dispatchEvent(new CustomEvent('loadmoredata'));
        }
    }

    handleColumnResizeStart(event) {
        event.preventDefault();
        event.stopPropagation();

        const fieldName = event.currentTarget.dataset.field;
        const header = this.template.querySelector(`th[data-field="${fieldName}"]`);

        if (!fieldName || !header) {
            return;
        }

        this.isResizingColumn = true;
        this.resizingField = fieldName;
        this.startX = event.clientX;
        this.startWidth = this.columnWidths[fieldName] || header.getBoundingClientRect().width;

        this.addColumnResizeListeners();
    }

    handleColumnResizeMove(event) {
        if (!this.isResizingColumn || !this.resizingField) {
            return;
        }

        const deltaX = event.clientX - this.startX;
        const nextWidth = Math.max(this.minColumnWidth, Math.round(this.startWidth + deltaX));

        this.columnWidths = {
            ...this.columnWidths,
            [this.resizingField]: nextWidth
        };
    }

    handleColumnResizeEnd() {
        this.isResizingColumn = false;
        this.resizingField = null;
        this.removeColumnResizeListeners();
    }

    addColumnResizeListeners() {
        globalThis.addEventListener('mousemove', this.boundResizeMove);
        globalThis.addEventListener('mouseup', this.boundResizeEnd);
    }

    removeColumnResizeListeners() {
        globalThis.removeEventListener('mousemove', this.boundResizeMove);
        globalThis.removeEventListener('mouseup', this.boundResizeEnd);
    }


    // DESARROLLO ACCIONES MASIVAS

    handleSelectAllChange(event) {
        const shouldSelectAll = event.target.checked;
        const visibleKeys = this.visibleSelectableRowKeys;
        const visibleSet = new Set(visibleKeys);
        this.isSelectAllActive = shouldSelectAll;

        if (shouldSelectAll) {
            const combined = new Set([...this.selectedRows, ...visibleKeys]);
            this.selectedRows = [...combined];
        } else {
            this.selectedRows = this.selectedRows.filter(key => !visibleSet.has(key));
        }

        this.emitSelectionChange();
    }

    handleRowSelection(event) {
        const { itemKey, isSelected } = event.detail;

        if (isSelected) {
            if (!this.selectedRows.includes(itemKey)) {
                this.selectedRows = [...this.selectedRows, itemKey];
            }
        } else {
            this.isSelectAllActive = false;
            this.selectedRows = this.selectedRows.filter(id => id !== itemKey);
        }

        this.emitSelectionChange();
    }

    emitSelectionChange() {
        this.dispatchEvent(new CustomEvent('selectionchange', {
            detail: { selectedRows: this.selectedRows }
        }));
    }

    syncSelectAllWithVisibleRows() {
        if (!this.isSelectionMode || !this.isSelectAllActive) {
            return;
        }

        const visibleKeys = this.visibleSelectableRowKeys;
        if (!visibleKeys.length) {
            return;
        }

        const previousCount = this.selectedRows.length;
        const mergedSelection = new Set([...this.selectedRows, ...visibleKeys]);
        this.selectedRows = [...mergedSelection];

        if (this.selectedRows.length !== previousCount) {
            this.emitSelectionChange();
        }
    }

    handleHeaderClick(event) {
        // Si el clic viene del handle de resize, no disparamos sort
        if (event.target.closest('.resize-handle')) {
            return;
        }
        const fieldName = event.currentTarget.dataset.field;
        if (!fieldName) return;

        this.dispatchEvent(new CustomEvent('sort', {
            detail: { fieldName }
        }));
    }
}