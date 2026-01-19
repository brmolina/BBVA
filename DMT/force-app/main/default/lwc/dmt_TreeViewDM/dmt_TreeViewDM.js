import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import DMTMarco_GCE_icon from '@salesforce/resourceUrl/DMTMarco_GCE_SVG';

/**
 * Sidebar that exposes search/filter parameters and emits its expand/collapse state.
 * No comments added for UI mechanics — only for functional intent.
 */
export default class Dmt_TreeViewDM extends NavigationMixin(LightningElement) {
    /* ----- Public context from parent ----- */
    @api clientid;
    @api searchdate;
    @api groupname;
    @api groupcode;

    /* ----- Internal state ----- */
    iconMarcoGCE = DMTMarco_GCE_icon;
    @track isExpanded = true;
    @track searchValue = '';
    @track filterValue = 'Y';

    /* Exposure filter values (business-driven) */
    filterOptions = [
        { label: 'With exposure', value: 'Y' },
        { label: 'With and Without Exposure', value: 'Y/N' }
    ];

    /* ----- Navigation ----- */

    /**
     * Opens the Global Clients Exposure component with the current group context.
     */
    goToGCE() {
        const pageReference = {
            type: 'standard__component',
            attributes: { componentName: 'hpgr__global_clients_exposure_cmp' },
            state: { c__customerId: this.groupcode }
        };

        this[NavigationMixin.GenerateUrl](pageReference).then(url => {
            window.open(url, '_blank');
        });
    }

    /**
     * Opens the client record directly (no NavigationMixin needed).
     */
    goToClientRecord() {
        window.open('/' + this.clientid, '_blank');
    }

    /* ----- Input handlers ----- */

    handleInputChange(event) {
        this.searchValue = event.target.value;
    }

    handleFilterChange(event) {
        this.filterValue = event.detail.value;
    }

    /* ----- Template helpers ----- */

    get hideElements() {
        return this.isExpanded
            ? 'slds-p-horizontal_small slds-show'
            : 'slds-p-horizontal_small slds-hide';
    }

    get toggleLabel() {
        return this.isExpanded ? 'Collapse panel' : 'Expand panel';
    }

    get cardClasses() {
        return this.isExpanded
            ? 'slds-size_12-of-12 sidebar-expanded'
            : 'slds-size_12-of-12 card-collapsed sidebar-collapsed';
    }

    /* ----- Expand/Collapse ----- */

    /**
     * Syncs internal expand/collapse state and notifies parent components.
     */
    togglePanel() {
        this.dispatchEvent(
            new CustomEvent('isExpandedSideBar', {
                bubbles: true,
                composed: true,
                detail: { isExpanded: !this.isExpanded }
            })
        );
        this.isExpanded = !this.isExpanded;
    }
}