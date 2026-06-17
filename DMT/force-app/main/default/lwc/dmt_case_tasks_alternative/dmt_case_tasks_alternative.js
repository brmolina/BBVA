import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getStepsFromUser from '@salesforce/apex/DMT_Case_Steps_Controller.getStepsFromUser';
import getTasksForMassiveClosure from '@salesforce/apex/DMT_Massive_Task_Closure_Controller.getTasksForMassiveClosure';
import DMT_No_Records from '@salesforce/label/c.DMT_No_Records';
import DMT_TaskInProgress from '@salesforce/label/c.DMT_TaskInProgress';
import DMT_ReturnedToRequester from '@salesforce/label/c.DMT_ReturnedToRequester';
import DMT_ClosedLines_Opportunities from '@salesforce/label/c.DMT_ClosedLines_Opportunities';

export default class Dmt_case_tasks_alternative extends LightningElement {
    @api taskCategory;
    _currentSearchList = null;
    activeTab = 'inProgress';
    isFiltering = false;
    //DESARROLLO ACCIONES MASIVAS
    @track isSelectionActive = false;
    @track selectedRecordsToClose = [];
    // NUEVO: Variable para controlar si el modal está abierto
    @track isModalOpen = false;
    @track massiveActionMode = 'closeApproval';
    closeForReviewEligibleTaskIds = new Set();

    columns = [
        {label: "TASK", fieldName: 'step', type: 'url'},
        {label: "TASK STATUS", fieldName: 'status', type: 'text'},
        {label: "LINE/OPP STATUS", fieldName: 'lineOppStatus', type: 'text'},
        {label: "RESULT", fieldName: 'result', type: 'text'},
        {label: "START DATE", fieldName: 'startDate', type: 'text'},
        {label: "END DATE", fieldName: 'endDate', type: 'text'},
        {label: "LINE/OPP ID", fieldName: 'lineOppId', type: 'text'},
        {label: "GROUP NAME", fieldName: 'groupClientName', type: 'text'},
        {label: "CLIENT", fieldName: 'client', type: 'text'},
        {label: "APPROVER", fieldName: 'approver', type: 'text'},
        {label: "USER", fieldName: 'user', type: 'text'},
        {label: "LINE/OPP", fieldName: 'lineOrOpportunity', type: 'text'},
        {label: "LINE DETAILS", fieldName: 'lineDetails', type: 'text'},
        {label: "ADDITIONAL DETAILS", fieldName: 'taskDetails', type: 'text'},
        {label: "APPROVER LABEL", fieldName: 'committeeLabel', type: 'text'},
        {label: "CASE FEATURE", fieldName: 'featureName', type: 'text'},
        {label: "LINE/OPP NAME", fieldName: 'oppLineName', type: 'url'}
    ];

    filters = [
        {label: 'Select one or several clients', fieldName: 'client', computedOptions: []},
        {label: 'Select one or several tasks status', fieldName: 'status', computedOptions: []},
        {label: 'Select if line or opportunity', fieldName: 'lineOrOpportunity', computedOptions: []},
    ];

    allData = [];
    rawInProgress = [];
    rawReturned = [];
    rawClosed = [];
    inProgressData = [];
    returnedData = [];
    closedData = [];
    allFlatDataForSearch = [];

    selectedFilters = {};
    isDataReceived = false;

    pageSize = 30;
    currentInProgressPage = 1;
    currentReturnedPage = 1;
    currentClosedPage = 1;

    filteredInProgress = [];
    filteredReturned = [];
    filteredClosed = [];

    //DESARROLLO ACCIONES MASIVAS
    closeApprovalButtonLabel = 'Close the approval';
    buttonCloseApprovalVariant = 'neutral'; // Botón blanco/gris estándar
    isClickedCloseApproval = false;

    //busqueda por fecha
    _currentDateList = null;

    labels = {
        DMT_No_Records,
        DMT_TaskInProgress,
        DMT_ReturnedToRequester,
        DMT_ClosedLines_Opportunities
    };

    get hasInProgress() { return this.inProgressData.length > 0; }
    get hasReturned() { return this.returnedData.length > 0; }
    get hasClosed() { return this.closedData.length > 0; }
    get inProgressTabClass() {
        return 'slds-tabs_default__item' + (this.activeTab === 'inProgress' ? ' slds-is-active' : '');
    }
    get returnedTabClass() {
        return 'slds-tabs_default__item' + (this.activeTab === 'returned' ? ' slds-is-active' : '');
    }
    get closedTabClass() {
        return 'slds-tabs_default__item' + (this.activeTab === 'closed' ? ' slds-is-active' : '');
    }

    get inProgressPanelClass() {
        return this.activeTab === 'inProgress' ? 'tab-panel tab-show' : 'tab-panel tab-hide';
    }
    get returnedPanelClass() {
        return this.activeTab === 'returned' ? 'tab-panel tab-show' : 'tab-panel tab-hide';
    }
    get closedPanelClass() {
        return this.activeTab === 'closed' ? 'tab-panel tab-show' : 'tab-panel tab-hide';
    }

    connectedCallback() {
        this.loadData();
    }

    handleDateFilter(event){
        const filteredList = event.detail.dataFind;
        const hasDateFilter = event.detail.startDate || event.detail.endDate;

        if (!hasDateFilter) {
            this._currentDateList = null;
        } else if (filteredList.length === 0) {
            this._currentDateList = [];
        } else {
            this._currentDateList = filteredList;
        }

        this.isFiltering = true;
        setTimeout(() => {
            this.applyFilters();
            this.isFiltering = false;
        }, 50);
    }
    loadData() {
        getStepsFromUser()
            .then(data => {
                this.allData = data;
                this.separateByCategory(data);
                this.buildFilterOptions();
                this.applyFilters();
                this.isDataReceived = true;
            })
            .catch(error => {
                this.error = error;
                this.isDataReceived = true;
            });
    }

    handleTabClick(event) {
        this.activeTab = event.currentTarget.dataset.tab;
    }


    separateByCategory(data) {
        const finishedNode = data.find(item => item.itemKey === 'Finished');
        const closedNode = data.find(item => item.itemKey === 'Closed');

        this.rawInProgress = data.filter(item => item.itemKey !== 'Finished' && item.itemKey !== 'Closed');
        this.rawReturned = finishedNode && finishedNode.subitems ? finishedNode.subitems : [];
        this.rawClosed = closedNode && closedNode.subitems ? closedNode.subitems : [];

        this.allFlatDataForSearch = this.flattenData([...this.rawInProgress, ...this.rawReturned, ...this.rawClosed]);

        this._flatDataMap = new Map();
        this.allFlatDataForSearch.forEach(item => {
            this._flatDataMap.set(item.itemKey, item);
        });
    }

    flattenData(items) {
        let result = [];
        items.forEach(item => {
            let itemCopy = JSON.parse(JSON.stringify(item));
            delete itemCopy.subitems;
            result.push(itemCopy);
            if (item.subitems && item.subitems.length > 0) {
                result = result.concat(this.flattenData(item.subitems));
            }
        });
        return result;
    }

    buildFilterOptions() {
        const allFlat = this.allFlatDataForSearch;
        this.filters = this.filters.map(filter => {
            const values = new Set();
            allFlat.forEach(item => {
                if (item[filter.fieldName]) {
                    values.add(item[filter.fieldName]);
                }
            });
            return {
                ...filter,
                computedOptions: Array.from(values).map(val => ({ label: val, value: val }))
            };
        });
    }

    handlePicklistChange(event) {
        const fieldsFromLWC = event.detail.data;
        const picklistName = event.detail.picklist;

        this.selectedFilters = {
            ...this.selectedFilters,
            [picklistName]: fieldsFromLWC.map(item => item.value)
        };

        this.isFiltering = true;
        setTimeout(() => {
            this.applyFilters();
            this.isFiltering = false;
        }, 50);
    }

        handleSearch(event) {
            const filteredFlatList = event.detail.dataFind;

            if (filteredFlatList.length === 0) {
                this._currentSearchList = [];
            } else {
                this._currentSearchList = filteredFlatList;
            }

            this.isFiltering = true;
            setTimeout(() => {
                this.applyFilters();
                this.isFiltering = false;
            }, 50);
        }

    filterTree(nodes, matchFn) {
        return nodes
            .map(node => {
                let filteredSubitems = node.subitems ? this.filterTree(node.subitems, matchFn) : [];
                if (matchFn(node) || filteredSubitems.length > 0) {
                    return { ...node, subitems: filteredSubitems };
                }
                return null;
            })
            .filter(Boolean);
    }

    filterTreeStrict(nodes, matchFn) {
        let result = [];
        for (const node of nodes) {
            const matchingSubs = node.subitems ? this.filterTreeStrict(node.subitems, matchFn) : [];
            if (matchFn(node)) {
                result.push({ ...node, subitems: matchingSubs });
            } else if (matchingSubs.length > 0) {
                result.push(...matchingSubs);
            }
        }
        return result;
    }

    applyFilters() {
        let baseInProgress = this.rawInProgress;
        let baseReturned = this.rawReturned;
        let baseClosed = this.rawClosed;

        let isSearchActive = this._currentSearchList !== null && this._currentSearchList.length < this.allFlatDataForSearch.length;

        if (this._currentSearchList !== null) {
            if (this._currentSearchList.length === 0) {
                this.inProgressData = [];
                this.returnedData = [];
                this.closedData = [];
                return;
            }

            if (isSearchActive) {
                const searchKeysSet = new Set(this._currentSearchList.map(item => item.itemKey));
                const matchFn = node => searchKeysSet.has(node.itemKey);

                baseInProgress = this.filterTree(baseInProgress, matchFn);
                baseReturned = this.filterTree(baseReturned, matchFn);
                baseClosed = this.filterTree(baseClosed, matchFn);
            }
        }

        // Date interval filter
        if (this._currentDateList !== null) {
            if (this._currentDateList.length === 0) {
                this.inProgressData = [];
                this.returnedData = [];
                this.closedData = [];
                return;
            }

            const dateKeysSet = new Set(this._currentDateList.map(item => item.itemKey));
            const dateFn = node => dateKeysSet.has(node.itemKey);

            baseInProgress = this.filterTreeStrict(baseInProgress, dateFn);
            baseReturned = this.filterTreeStrict(baseReturned, dateFn);
            baseClosed = this.filterTreeStrict(baseClosed, dateFn);
        }

        const activeFilters = Object.keys(this.selectedFilters).filter(
            field => this.selectedFilters[field] && this.selectedFilters[field].length > 0
        );

        if (activeFilters.length === 0) {
            this.filteredInProgress = baseInProgress;
            this.filteredReturned = baseReturned;
            this.filteredClosed = baseClosed;
        } else {
            this.filteredInProgress = this.filterByPicklists(baseInProgress, activeFilters);
            this.filteredReturned = this.filterByPicklists(baseReturned, activeFilters);
            this.filteredClosed = this.filterByPicklists(baseClosed, activeFilters);
        }

        this.currentInProgressPage = 1;
        this.currentReturnedPage = 1;
        this.currentClosedPage = 1;

        this.inProgressData = this.filteredInProgress.slice(0, this.pageSize);
        this.returnedData = this.filteredReturned.slice(0, this.pageSize);
        this.closedData = this.filteredClosed.slice(0, this.pageSize);
    }

    handleScroll() {
        if (this.activeTab === 'inProgress' && this.inProgressData.length < this.filteredInProgress.length) {
            this.currentInProgressPage++;
            const nextItems = this.filteredInProgress.slice(0, this.currentInProgressPage * this.pageSize);
            this.inProgressData = [...nextItems];
        }
        else if (this.activeTab === 'returned' && this.returnedData.length < this.filteredReturned.length) {
            this.currentReturnedPage++;
            const nextItems = this.filteredReturned.slice(0, this.currentReturnedPage * this.pageSize);
            this.returnedData = [...nextItems];
        }
        else if (this.activeTab === 'closed' && this.closedData.length < this.filteredClosed.length) {
            this.currentClosedPage++;
            const nextItems = this.filteredClosed.slice(0, this.currentClosedPage * this.pageSize);
            this.closedData = [...nextItems];
        }
    }

    filterByPicklists(data, activeFilters) {
        return data.filter(record => {
            const flat = this._flatDataMap.get(record.itemKey);
            if (flat) {
                const passes = activeFilters.every(field => this.selectedFilters[field].includes(flat[field]));
                if (passes) return true;
            }
            if (record.subitems && record.subitems.length > 0) {
                return record.subitems.some(sub => {
                    const subFlat = this._flatDataMap.get(sub.itemKey);
                    if (!subFlat) return false;
                    return activeFilters.every(field => this.selectedFilters[field].includes(subFlat[field]));
                });
            }

            return false;
        });
    }

    //DESARROLLO ACCIONES MASIVAS

    get containerStyle() {
    // Si está activo, creamos una variable con 80px. Si no, 0px.
    return this.isSelectionActive ? '--footer-height: 110px;' : '--footer-height: 0px;';
}

    extractTaskIdFromSelectionKey(selectionKey) {
        if (!selectionKey) {
            return null;
        }
        const keyAsString = String(selectionKey);
        return keyAsString.includes('_') ? keyAsString.substring(keyAsString.lastIndexOf('_') + 1) : keyAsString;
    }

    getRootSelectionKeys(records) {
        return (records || [])
            .map(record => record?.itemKey)
            .filter(key => !!key);
    }

    showSelectionWarning(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Information',
            message,
            variant: 'info'
        }));
    }

    async activateCloseForReviewSelection() {
        this.selectedRecordsToClose = [];
        this.closeForReviewEligibleTaskIds = new Set();

        const candidateKeys = [
            ...this.getRootSelectionKeys(this.filteredInProgress),
            ...this.getRootSelectionKeys(this.filteredReturned),
            ...this.getRootSelectionKeys(this.filteredClosed)
        ];

        if (candidateKeys.length === 0) {
            this.isSelectionActive = false;
            this.showSelectionWarning('None of the selected tasks are available to be closed for review.');
            return;
        }

        try {
            const tasks = await getTasksForMassiveClosure({ selectionKeys: candidateKeys });
            const eligibleTaskIds = new Set(
                (tasks || [])
                    .filter(task => task.returnToProposalDisabled !== true)
                    .map(task => String(task.taskId))
            );

            const totalEligible = eligibleTaskIds.size;

            if (totalEligible === 0) {
                this.isSelectionActive = false;
                this.showSelectionWarning('None of the selected tasks are available to be closed for review.');
                return;
            }

            this.closeForReviewEligibleTaskIds = eligibleTaskIds;
            this.isSelectionActive = true;
        } catch {
            this.isSelectionActive = false;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Unable to load eligible tasks for close for review.',
                variant: 'error'
            }));
        }
    }

    handleToggleClickCloseApproval() {
        if (this.massiveActionMode === 'closeForReview') {
            this.applyFilters();
            this.selectionWarningMessage = '';
        }

        this.massiveActionMode = 'closeApproval';

        // Si estamos abriendo la selección (isClickedCloseApproval es false)
        if (!this.isClickedCloseApproval) {
            // Obtener datos filtrados según el tab activo
            let currentFilteredData = [];
            if (this.activeTab === 'inProgress') {
                currentFilteredData = this.filteredInProgress;
            } else if (this.activeTab === 'returned') {
                currentFilteredData = this.filteredReturned;
            } else if (this.activeTab === 'closed') {
                currentFilteredData = this.filteredClosed;
            }

            // Si no hay datos disponibles, mostrar mensaje y no activar selección
            if (currentFilteredData.length === 0) {
                this.showSelectionWarning('There is no task available to be closed for approval.');
                return;
            }
        }

        // Invierte el estado (de false a true, y viceversa si se vuelve a clicar)
        this.isClickedCloseApproval = !this.isClickedCloseApproval;

        if (this.isClickedCloseApproval) {
            this.closeApprovalButtonLabel = 'Select tasks to close';
            this.buttonCloseApprovalVariant = 'brand';
            this.isSelectionActive = true;
        } else {
            this.closeApprovalButtonLabel = 'Close the approval';
            this.buttonCloseApprovalVariant = 'neutral';
            this.isSelectionActive = false;
        }
    }

    async handleClickCloseForReview() {
        this.massiveActionMode = 'closeForReview';
        this.isClickedCloseApproval = false;
        this.closeApprovalButtonLabel = 'Close the approval';
        this.buttonCloseApprovalVariant = 'neutral';
        await this.activateCloseForReviewSelection();
    }

    get closeForReviewButtonVariant() {
        return this.isSelectionActive && this.massiveActionMode === 'closeForReview' ? 'brand' : 'neutral';
    }

    get isCloseForReviewMode() {
        return this.massiveActionMode === 'closeForReview';
    }

    handleSelectionChange(event) {
        this.selectedRecordsToClose = event.detail.selectedRows;
    }

    // NUEVO: Al pulsar Cancelar
    handleCancelSelection() {
        this.isSelectionActive = false; // Oculta los checkboxes y el footer
        this.selectedRecordsToClose = []; // Limpiamos la memoria por si acaso
        this.closeForReviewEligibleTaskIds = new Set();
        this.closeApprovalButtonLabel = 'Close the approval';
        this.buttonCloseApprovalVariant = 'neutral';
        this.isClickedCloseApproval = false;
        this.massiveActionMode = 'closeApproval';
        this.applyFilters();
    }

    handleCloseModal() {
        this.isModalOpen = false;
        this.isSelectionActive = false;
        this.selectedRecordsToClose = [];
        this.closeForReviewEligibleTaskIds = new Set();
        this.closeApprovalButtonLabel = 'Close the approval';
        this.buttonCloseApprovalVariant = 'neutral';
        this.isClickedCloseApproval = false;
        this.massiveActionMode = 'closeApproval';
    }

    // NUEVO: Al pulsar Apply
    handleApplySelection() {
        // Validación de seguridad: Comprobar que hayan seleccionado algo
        if (this.selectedRecordsToClose.length === 0) {
            const isCloseForReview = this.massiveActionMode === 'closeForReview';
            const message = isCloseForReview
                ? 'None of the selected tasks are available to be closed for review.'
                : 'You have not selected any task to be closed for approval.';

            this.dispatchEvent(new ShowToastEvent({
                title: 'Information',
                message,
                variant: 'info'
            }));
            return; // Detenemos la ejecución para que no se abra el modal
        }

        if (this.massiveActionMode === 'closeForReview') {
            const eligibleSelections = this.selectedRecordsToClose.filter(selectionKey => {
                const taskId = this.extractTaskIdFromSelectionKey(selectionKey);
                return taskId && this.closeForReviewEligibleTaskIds.has(taskId);
            });

            if (eligibleSelections.length === 0) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Information',
                    message: 'None of the selected tasks are available to be closed for review.',
                    variant: 'info'
                }));
                return;
            }

            this.selectedRecordsToClose = eligibleSelections;
        }

        // Si todo está bien, abrimos el modal
        this.isModalOpen = true;
    }

    handleApplyClosure(event) {
        const dataFromModal = event.detail;
        console.log('Datos listos para procesar en Apex:', JSON.stringify(dataFromModal));

        this.isModalOpen = false;
        this.isSelectionActive = false;
        this.selectedRecordsToClose = [];
        this.closeForReviewEligibleTaskIds = new Set();
        this.closeApprovalButtonLabel = 'Close the approval';
        this.buttonCloseApprovalVariant = 'neutral';
        this.isClickedCloseApproval = false;
        this.massiveActionMode = 'closeApproval';

        this.isDataReceived = false;
        this.loadData();
    }
}