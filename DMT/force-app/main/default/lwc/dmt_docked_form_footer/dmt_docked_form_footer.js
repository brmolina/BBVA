import { LightningElement, track, api } from 'lwc';

export default class DmtDockedFormFooter extends LightningElement {

    @track showErrorPopover = false;

    _isLoading = false;
    @api get isLoading() { return this._isLoading; }
    set isLoading(value) {
        this._isLoading = value;
        // Re-show the popover once loading finishes if there is a pending error
        if (!value && this._hasError) {
            this.showErrorPopover = true;
        }
    }

    @api errorMessage = '';

    _hasError = false;
    @api get hasError() { return this._hasError; }
    set hasError(value) {
        this._hasError = value;
        // Show the popover automatically when an error is set
        if (value) {
            this.showErrorPopover = true;
        }
    }

    // Only show the popover when not in a loading state
    get showErrorPopoverIfNotLoading() {
        return this.hasError && this.showErrorPopover && !this.isLoading;
    }

    handleSave() {
        this.dispatchEvent(new CustomEvent('save', { bubbles: true, composed: true }));
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel', { bubbles: true, composed: true }));
        this.closeErrorPopover();
    }

    handleErrorButtonClick() {
        this.showErrorPopover = !this.showErrorPopover;
    }

    closeErrorPopover() {
        this.showErrorPopover = false;
    }
}