import { LightningElement, api } from 'lwc';

export default class Dmt_TableHeaderSection extends LightningElement {
    _showcopypaste = false;
    _isreadonlyuser = false;
    _withoutstyle = false;
    @api rowscopypaste = [];           // rows sent to the copy
    @api tablecolumnscopypaste = [];   // table comlumns for copy

    @api context;                 // Context
    @api titletable;  // Title header
    @api customstyle;





    /**
     * Normalizes the value to a boolean.
     * - If it's a boolean → returns it as is.
     * - If it's a string → returns true only if it's "true" (case-insensitive).
     * - Anything else → returns false.
     * @param {any} value
     * @returns {boolean}
     */
    normalizeBoolean(value) {
        if (typeof value === 'boolean') {
            return value;
        }
        if (typeof value === 'string') {
            return value.trim().toLowerCase() === 'true';
        }
        return false;
    }

    @api
    get showcopypaste() {
        return this._showcopypaste;
    }
    set showcopypaste(value) {
        this._showcopypaste = this.normalizeBoolean(value);
    }

    @api
    get isreadonlyuser() {
        return this._isreadonlyuser;
    }
    set isreadonlyuser(value) {
        this._isreadonlyuser = this.normalizeBoolean(value);
    }
    @api
    get withoutformat() {
        return this._withoutstyle;
    }
    set withoutformat(value) {
        this._withoutstyle = this.normalizeBoolean(value);
    }

    get customStyle(){
        return this.withoutformat === true ? this.customstyle : this.customstyle;
    }

}