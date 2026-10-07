import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';
import searchGroups from '@salesforce/apex/DMT_BussinessPlanController.searchGroups';

export default class DmtBpGroupSelectorModal extends LightningModal {

    // Group currently applied (if any) — used to pre-select the picker and to allow reverting
    @api currentGroupId;
    @api currentGroupName;

    selectedGroupId;
    selectedGroupName;

    @track groupOptions = [];

    connectedCallback() {
        this.selectedGroupId = this.currentGroupId || null;
        this.selectedGroupName = this.currentGroupName || null;
    }

    get isConfirmDisabled() {
        return !this.selectedGroupId;
    }

    get hasCurrentOverride() {
        return !!this.currentGroupId;
    }

    handleChange(event) {
        const { value, label } = event.detail.data;
        this.selectedGroupId = value || null;
        this.selectedGroupName = label || null;
    }

    async handleSearch(event) {
        const { term } = event.detail;
        if (!term || term.length < 2) {
            this.groupOptions = [];
            return;
        }
        try {
            const results = await searchGroups({ searchTerm: term });
            this.groupOptions = results || [];
        } catch (e) {
            console.error('Error searching Groups:', e);
        }
    }

    handleCancel() {
        this.close(null);
    }

    handleReset() {
        this.close({ reset: true });
    }

    handleConfirm() {
        this.close({
            groupId: this.selectedGroupId,
            groupName: this.selectedGroupName
        });
    }
}