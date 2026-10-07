import { LightningElement, track } from 'lwc';
import getStepsFromUser from '@salesforce/apex/DMT_Case_Steps_Controller.getStepsFromUser';
import DMT_No_Records from '@salesforce/label/c.DMT_No_Records';
import DMT_TaskInProgress from '@salesforce/label/c.DMT_TaskInProgress';

const PAGE_SIZE = 20;
const SCROLL_THRESHOLD_PX = 60;

/**
 * Mobile optimized version of dmt_case_tasks_alternative.
 * Renders a flat, lightweight table (no nested tree / no shadow-DOM heavy
 * desktop grid) so it stays visible and responsive on small screens.
 * Only shows the "in progress" tasks with a reduced set of columns,
 * keeps the general search bar and drops bulk actions/tabs/column filters.
 */
export default class Dmt_case_tasks_mobile extends LightningElement {
    @track isDataReceived = false;
    isFiltering = false;

    allFlatDataForSearch = [];
    filteredList = [];
    displayedRows = [];

    labels = {
        DMT_No_Records,
        DMT_TaskInProgress
    };

    get hasData() {
        return this.displayedRows.length > 0;
    }

    get hasMoreData() {
        return this.displayedRows.length < this.filteredList.length;
    }

    connectedCallback() {
        this.loadData();
    }

    loadData() {
        getStepsFromUser()
            .then(data => {
                const rawInProgress = (data || []).filter(
                    item => item.itemKey !== 'Finished' && item.itemKey !== 'Closed'
                );
                this.allFlatDataForSearch = this.flattenData(rawInProgress).map(item => this.mapRow(item));
                this.filteredList = this.allFlatDataForSearch;
                this.resetPaging();
                this.isDataReceived = true;
            })
            .catch(error => {
                this.error = error;
                this.isDataReceived = true;
            });
    }

    flattenData(items) {
        let result = [];
        (items || []).forEach(item => {
            const itemCopy = JSON.parse(JSON.stringify(item));
            delete itemCopy.subitems;
            result.push(itemCopy);
            if (item.subitems && item.subitems.length > 0) {
                result = result.concat(this.flattenData(item.subitems));
            }
        });
        return result;
    }

    /**
     * Reduces a task node down to the plain fields the mobile table needs.
     * Links are only rendered when the URL points to a real record ('/...'),
     * the "c-modal-container" internal values are shown as plain text.
     */
    mapRow(item) {
        const taskUrl = item.step && item.step.urlValue && item.step.urlValue.startsWith('/') ? item.step.urlValue : null;
        const oppUrl = item.oppLineName && item.oppLineName.urlValue && item.oppLineName.urlValue.startsWith('/') ? item.oppLineName.urlValue : null;

        return {
            key: item.itemKey,
            taskLabel: item.step ? item.step.urlLabel : '',
            taskUrl,
            isTaskLink: !!taskUrl,
            client: item.client || '',
            oppLabel: item.oppLineName ? item.oppLineName.urlLabel : '',
            oppUrl,
            isOppLink: !!oppUrl,
            code: item.lineOppId || ''
        };
    }

    resetPaging() {
        this.displayedRows = this.filteredList.slice(0, PAGE_SIZE);
    }

    handleSearch(event) {
        const filteredFlatList = event.detail.dataFind || [];

        this.isFiltering = true;
        setTimeout(() => {
            this.filteredList = filteredFlatList;
            this.resetPaging();
            this.isFiltering = false;
        }, 50);
    }

    handleScroll(event) {
        const el = event.target;
        const reachedBottom = el.scrollHeight - el.scrollTop - el.clientHeight < SCROLL_THRESHOLD_PX;
        if (reachedBottom && this.hasMoreData) {
            this.displayedRows = this.filteredList.slice(0, this.displayedRows.length + PAGE_SIZE);
        }
    }
}