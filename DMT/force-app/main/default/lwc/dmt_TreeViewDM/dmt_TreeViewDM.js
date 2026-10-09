import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import DMTMarco_GCE_icon from '@salesforce/resourceUrl/DMTMarco_GCE_SVG';

import goToGCEText from '@salesforce/label/c.DMT_GoToGCEText';
import dataFromText from '@salesforce/label/c.dmt_cl_DataFrom_Text';
import collapsePanelText from '@salesforce/label/c.DMT_CollapsePanelText';
import expandPanelText from '@salesforce/label/c.DMT_ExpandPanelText';
import searchClientsText from '@salesforce/label/c.DMT_SearchClientsText';
import clientsFilterText from '@salesforce/label/c.DMT_ClientsFilterText';
import withExposureText from '@salesforce/label/c.DMT_WithExposureText';
import withAndWithoutExposureText from '@salesforce/label/c.DMT_WithAndWithoutExposureText';
import goToClientInfoText from '@salesforce/label/c.DMT_GoToClientInfoText';
import selectFilterText from '@salesforce/label/c.DMT_SelectFilterText';
import searchClientsTextWhithTreePoints from '@salesforce/label/c.DMT_SearchClientsTextWhithTreePoints';

/**
 * Sidebar that exposes search/filter parameters and emits its expand/collapse state.
 * No comments added for UI mechanics — only for functional intent.
 */
export default class Dmt_TreeViewDM extends NavigationMixin(LightningElement) {
    /* ----- Public context from parent ----- */
    @api clientid;
    @api searchdate;
    @api groupname;

    _groupcode;
    @api
    get groupcode() {
        return this._groupcode;
    }
    set groupcode(value) {
        if (this._groupcode === value) {
            return;
        }
        this._groupcode = value;
        // CIBGLOBALD-4344 - A new group context resets the exposure filter back to its default
        // and re-arms the With-Exposure-empty fallback for that new context.
        this._userChangedFilter = false;
        this.filterValue = 'Y';
    }

    /* ----- Internal state ----- */
    iconMarcoGCE = DMTMarco_GCE_icon;

    isExpanded = true;
    searchValue = '';
    filterValue = 'Y';
    // CIBGLOBALD-4344 - True once the user has deliberately picked a filter option, so the
    // With-Exposure-empty fallback stops overriding their explicit choice.
    _userChangedFilter = false;

    label = {
        goToGCEText,
        dataFromText,
        collapsePanelText,
        expandPanelText,
        searchClientsText,
        clientsFilterText,
        withExposureText,
        withAndWithoutExposureText,
        goToClientInfoText,
        selectFilterText,
        searchClientsTextWhithTreePoints
    };

    /* Exposure filter values (business-driven) */
    get filterOptions() {
        return [
            { label: this.label.withExposureText, value: 'Y' },
            { label: this.label.withAndWithoutExposureText, value: 'Y/N' }
        ];
    }

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

        this[NavigationMixin.GenerateUrl](pageReference).then((url) => {
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
        this._userChangedFilter = true;
        this.filterValue = event.detail.value;
    }

    /**
     * CIBGLOBALD-4344 - Raised by c-dmt_-main-client-selection-table when a full "With Exposure"
     * fetch comes back with zero clients. Only acts on the default/initial load — if the user has
     * already deliberately picked a filter themselves, their choice is respected even if empty.
     */
    handleExposureFallback() {
        if (this._userChangedFilter) {
            return;
        }
        this.filterValue = 'Y/N';
    }

    /* ----- Template helpers ----- */
    get hideElements() {
        return this.isExpanded ? 'slds-p-left_large slds-show table-flex slds-p-bottom_x-small' : 'slds-hide';
    }

    get toggleLabel() {
        return this.isExpanded ? this.label.collapsePanelText : this.label.expandPanelText;
    }
    get expandedClasses() {
    return this.isExpanded ? 'slds-show' : 'slds-hide';
}

get collapsedClasses() {
    return this.isExpanded ? 'slds-hide' : 'slds-show';
}

    /* ----- Expand/Collapse ----- */
    /**
     * Syncs internal expand/collapse state and notifies parent components.
     */
    togglePanel() {
        this.dispatchEvent(
            new CustomEvent('sidebartoggle', {
                bubbles: true,
                composed: true,
                detail: { isExpanded: !this.isExpanded }
            })
        );

        this.isExpanded = !this.isExpanded;
    }

}