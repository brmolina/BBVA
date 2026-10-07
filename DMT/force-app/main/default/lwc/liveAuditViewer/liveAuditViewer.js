import { LightningElement, track } from 'lwc';
import getAuditLogs from '@salesforce/apex/AuditTrailController.getAuditLogs';

const PAGE_SIZE = 200;

const COLUMNS = [
    { label: 'Date', fieldName: 'CreatedDate', type: 'date',
      typeAttributes: {
          year: 'numeric', month: '2-digit', day: '2-digit',
          hour: '2-digit', minute: '2-digit', second: '2-digit'
      },
      fixedWidth: 170
    },
    { label: 'User', fieldName: 'CreatedByName', type: 'text', fixedWidth: 120 },
    { label: 'Section', fieldName: 'Section', type: 'text', fixedWidth: 120 },
    { label: 'Action', fieldName: 'Display', type: 'text', wrapText: true }
];

export default class LiveAuditViewer extends LightningElement {
    @track allData = [];      // The full set of records loaded from Apex
    @track filteredData = []; // The subset of records matching the search term

    columns = COLUMNS;
    isLoading = true;
    searchTerm = '';
    isNextDisabled = false;

    // Pagination markers (Keyset)
    lastId = null;
    lastDate = null;

    connectedCallback() {
        this.loadData();
    }

    /**
     * @param {Boolean} append - If true, adds results to existing data. If false, replaces.
     */
    loadData(append = false) {
        this.isLoading = true;

        getAuditLogs({
            limitSize: PAGE_SIZE,
            lastId: this.lastId,
            lastDate: this.lastDate
        })
        .then(result => {
            // Flatten CreatedBy.Name for the datatable
            const formatted = result.map(row => ({
                ...row,
                CreatedByName: row.CreatedBy?.Name
            }));

            // Update master data
            this.allData = append ? [...this.allData, ...formatted] : formatted;

            // Re-apply filter immediately
            this.applyLocalFilter();

            // Set markers for the next "Load More" action
            if (result.length > 0) {
                const lastRecord = result[result.length - 1];
                this.lastId = lastRecord.Id;
                this.lastDate = lastRecord.CreatedDate;
            }

            this.isNextDisabled = (result.length < PAGE_SIZE);
            this.isLoading = false;
        })
        .catch(error => {
            console.error('Audit Trail Error:', error);
            this.isLoading = false;
        });
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value.toLowerCase();
        this.applyLocalFilter();
    }

    applyLocalFilter() {
        if (!this.searchTerm) {
            this.filteredData = [...this.allData];
        } else {
            this.filteredData = this.allData.filter(row => {
                const searchStr = this.searchTerm;
                return (
                    (row.Display && row.Display.toLowerCase().includes(searchStr)) ||
                    (row.Section && row.Section.toLowerCase().includes(searchStr)) ||
                    (row.Action && row.Action.toLowerCase().includes(searchStr)) ||
                    (row.CreatedByName && row.CreatedByName.toLowerCase().includes(searchStr))
                );
            });
        }
    }

    handleLoadMore() {
        this.loadData(true);
    }

    handleRefresh() {
        this.lastId = null;
        this.lastDate = null;
        this.allData = [];
        this.loadData(false);
    }
}