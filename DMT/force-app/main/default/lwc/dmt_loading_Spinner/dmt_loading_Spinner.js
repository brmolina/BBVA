import { LightningElement, api } from 'lwc';

export default class LoadingSpinner extends LightningElement {
    // Public properties
    @api alternativeText = 'loading data';
    @api size = 'medium';
    @api variant = 'brand';
    _isLoading = false;
    @api 
    get isLoading() {
        return this._isLoading;
    }
    set isLoading(value) {
        console.log('Setting isLoading to:', value);
        this._isLoading = value == true || value == 'true';
    }
}