import { LightningElement, api, track } from 'lwc';
import loadCommitments from '@salesforce/apex/DMT_CommitmentsTableController.loadCommitments';

export default class Dmt_table_commitments extends LightningElement {
    opportunityValue;
    oppStateValue;
    isEditModeValue = false;
    isReadOnlyUserValue = false;

    @track rows = [];
    @track hasRows = false;
    @track isLoading = false;

    selectedRowId = null;
    hasLoadedData = false;

    @api
    get opportunity() {
        return this.opportunityValue;
    }
    set opportunity(value) {
        this.opportunityValue = value;
        console.log('this.opportunityValue after:', this.opportunityValue);

        this.tryLoadData();
    }

    @api
    get oppState() {
        return this.oppStateValue;
    }
    set oppState(value) {
        this.oppStateValue = value;
        console.log('this.oppStateValue after:', this.oppStateValue);
    }

    @api
    get isEditMode() {
        return this.isEditModeValue;
    }
    set isEditMode(value) {
        this.isEditModeValue = value === true || value === 'true';
        console.log('this.isEditModeValue after:', this.isEditModeValue);
    }

    @api
    get isReadOnlyUser() {
        return this.isReadOnlyUserValue;
    }
    set isReadOnlyUser(value) {
        this.isReadOnlyUserValue = value === true || value === 'true';
        console.log('this.isReadOnlyUserValue after:', this.isReadOnlyUserValue);
    }

    connectedCallback() {
        console.log('connectedCallback dmt_table_commitments');
    }

    // renderedCallback() {
    //     console.log('renderedCallback dmt_table_commitments');
    //     console.log('Opportunity:', this.opportunityValue);
    //     console.log('OppState:', this.oppStateValue);
    //     console.log('isEditMode:', this.isEditModeValue);
    //     console.log('isReadOnlyUser:', this.isReadOnlyUserValue);
    //     console.log('canSelect:', this.canSelect);
    // }

    tryLoadData() {
        if (this.hasLoadedData) {
            return;
        }

        if (!this.opportunityValue) {
            return;
        }

        this.hasLoadedData = true;
        this.loadTableData();
    }

    async loadTableData() {
        this.isLoading = true;

        try {
            const response = await loadCommitments({
                opportunityId: this.opportunityValue
            });

            this.rows = (response.rows || []).map(row => {
                return {
                    ...row,
                    rowClass: 'tableRow'
                };
            });

            this.hasRows = response.hasRows;
            console.log('Commitments loaded:', JSON.stringify(this.rows));
        } catch (error) {
            console.error('Error loading commitments:', JSON.stringify(error));
            this.rows = [];
            this.hasRows = false;
        } finally {
            this.isLoading = false;
        }
    }

    get canSelect() {
        const editableByState =
            this.oppStateValue === 'Draft' || this.oppStateValue === 'Ready to close';

        return editableByState && !this.isReadOnlyUserValue && this.isEditModeValue;
    }

    handleRowClick(event) {
        if (!this.canSelect) {
            return;
        }

        const clickedRowId = event.currentTarget.dataset.id;

        if (this.selectedRowId === clickedRowId) {
            this.selectedRowId = null;
        } else {
            this.selectedRowId = clickedRowId;
        }

        this.rows = this.rows.map(row => {
            return {
                ...row,
                rowClass: row.id === this.selectedRowId ? 'tableRow selectedRow' : 'tableRow'
            };
        });

        console.log('Selected row:', this.selectedRowId);
    }
}