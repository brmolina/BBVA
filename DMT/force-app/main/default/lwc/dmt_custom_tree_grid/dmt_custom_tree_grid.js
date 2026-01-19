import {
    LightningElement,
    track,
    api
} from 'lwc';

export default class Dmt_custom_tree_grid extends LightningElement {

    @api columns;
    @api columnsParent;
    @api columnsChildren;
    @api modelData;
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
    selectedFilters = {};

    /**
     * Opened at launch
     */
    connectedCallback() {
        this.processData();
    }

    get searchFiltersBar() {
        return this.notEmpty && (this.search || (this.filters && this.filters.length > 0) );
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
        this.processedData = this.modelData.map(item => processNode(item, 0, undefined));
        if (this.processedData.length > 0) {
            this.notEmpty = true;
        }
        this.originalProcessedData = [...this.processedData];
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

        // Trigger reactive updates
        this.isDataProcessed = false;
        this.isDataProcessed = true;
    }
}