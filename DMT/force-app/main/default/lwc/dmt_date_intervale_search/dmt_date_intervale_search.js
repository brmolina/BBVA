import {
    LightningElement,
    api,
    track
} from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import styles from '@salesforce/resourceUrl/RemoveDateFormatStyle';

export default class Dmt_date_intervale_search extends LightningElement {
    @track startDate;
    @track endDate;
    @track rangeErrorMessage = '';
    _isStyleLoaded = false;

    _records = [];

    @api
    get records() {
        return this._records;
    }

    get minEndDate() {
        return this.startDate || null;
    }

    get maxStartDate() {
        return this.endDate || null;
    }

    get hasRangeError() {
        return this.rangeErrorMessage !== '';
    }

    renderedCallback(){
        if (this._isStyleLoaded) {
            return;
        }
        this._isStyleLoaded = true;
        loadStyle(this, styles)
            .then(() => {
                globalThis.console.log('Files loaded.');
            })
            .catch(error => {
                globalThis.console.log('Error ' + (error?.body?.message || error?.message || error));
            });
    }

    set records(value) {
        this._records = value && Array.isArray(value) ? value : [];
        this.filterAndDispatch();
    }

    handleStartDateChange(event) {
        this.startDate = event.target.value;
        if (this.validateDateRange()) {
            this.filterAndDispatch();
        }
    }

    handleEndDateChange(event) {
        this.endDate = event.target.value;
        if (this.validateDateRange()) {
            this.filterAndDispatch();
        }
    }

    validateDateRange() {
        if (this.startDate && this.endDate && this.startDate > this.endDate) {
            this.rangeErrorMessage = 'End Date cannot be earlier than Start Date.';
            return false;
        }

        this.rangeErrorMessage = '';
        return true;
    }

    filterAndDispatch() {
        if (!this.validateDateRange()) {
            return;
        }

        let filtered = [...this._records];

        if (this.startDate || this.endDate) {
            const from = this.startDate ? new Date(this.startDate + 'T00:00:00') : null;
            const to = this.endDate ? new Date(this.endDate + 'T23:59:59') : null;

            filtered = filtered.filter(record => {
                const recStart = record.startDate ? this.parseDate(record.startDate) : null;
                console.log('DATE DEBUG - raw:', record.startDate, '| parsed:', recStart, '| from:', from, '| to:', to);
                if (!recStart || isNaN(recStart.getTime())) return false;
                if (from && recStart < from) return false;
                if (to && recStart > to) return false;
                return true;
            });
        }

        this.dispatchEvent(new CustomEvent('dateselect', {
            detail: { dataFind: filtered, startDate: this.startDate, endDate: this.endDate }
        }));
    }

    parseDate(dateStr) {
        if (!dateStr) return null;
        const months = {
            'jan': 0, 'feb': 1, 'mar': 2, 'apr': 3, 'may': 4, 'jun': 5,
            'jul': 6, 'aug': 7, 'sep': 8, 'oct': 9, 'nov': 10, 'dec': 11,
            'ene': 0, 'feb': 1, 'mar': 2, 'abr': 3, 'may': 4, 'jun': 5,
            'jul': 6, 'ago': 7, 'sep': 8, 'oct': 9, 'nov': 10, 'dic': 11
        };
        // Format: dd/MMM/yyyy HH:mm:ss
        const parts = dateStr.split(' ');
        const dateParts = parts[0].split('/');
        if (dateParts.length < 3) return null;
        const day = parseInt(dateParts[0], 10);
        const monthStr = dateParts[1].toLowerCase().replace(/\./g, '');
        const year = parseInt(dateParts[2], 10);
        const month = months[monthStr];
        if (month === undefined) return null;
        if (parts.length > 1 && parts[1]) {
            const timeParts = parts[1].split(':');
            return new Date(year, month, day, parseInt(timeParts[0], 10) || 0, parseInt(timeParts[1], 10) || 0, parseInt(timeParts[2], 10) || 0);
        }
        return new Date(year, month, day);
    }
}