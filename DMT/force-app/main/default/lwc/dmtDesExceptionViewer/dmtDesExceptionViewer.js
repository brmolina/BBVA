import { LightningElement, track, wire } from 'lwc';
import getRecords from '@salesforce/apex/DMT_Des_ExceptionViewerController.getRecords';

export default class DmtDesExceptionViewer extends LightningElement {
    @track records = [];
    @track filteredRecords = [];
    @track searchTimestampFrom = '';
    @track searchTimestampTo = '';
    @track showError = false;
    @track errorMessage = '';
    @track lastTimestamp = null;
    @track isLoading = false;
    @track projectFilter = '';
    @track typeFilter = '';
    @track classFilter = '';
    @track methodFilter = '';

    DEFAULT_LIMIT = 10;
    limitSize = this.DEFAULT_LIMIT;

    columns = [
        { label: 'Fecha Creación', fieldName: 'Timestamp__c', type: 'date' },
        { label: 'Proyecto', fieldName: 'Project__c', type: 'text' },
        { label: 'Tipo', fieldName: 'Type__c', type: 'text' },
        { label: 'Clase', fieldName: 'Class_Name__c', type: 'text' },
        { label: 'Método', fieldName: 'MethodName__c', type: 'text' },
        { label: 'Mensaje', fieldName: 'Message__c', type: 'text' }
    ];

    handleInputChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value;
    }

    handleSearch() {
        if (!this.searchTimestampFrom || !this.searchTimestampTo) {
            this.showError = true;
            this.errorMessage = 'Los campos "Fecha Desde" y "Fecha Hasta" son obligatorios.';
            return;
        }

        const fromDate = new Date(this.searchTimestampFrom);
        const toDate = new Date(this.searchTimestampTo);

        if (toDate < fromDate) {
            this.showError = true;
            this.errorMessage = '"Fecha Desde" no puede ser anterior a "Fecha Hasta".';
            return;
        }

        this.showError = false;
        this.errorMessage = '';
        this.lastTimestamp = null;
        this.records = [];
        this.fetchRecords();
    }

    fetchRecords() {
        if (this.isLoading) return;
        this.isLoading = true;

        const toDate = new Date(this.searchTimestampTo);
        toDate.setHours(23, 59, 59, 999);
        const adjustedToTimestamp = toDate.toISOString();

        getRecords({
            timestampFrom: this.searchTimestampFrom,
            timestampTo: adjustedToTimestamp,
            limitSize: this.limitSize,
            lastTimestamp: this.lastTimestamp
        })
        .then(data => {
            if (data && data.length > 0) {
                this.records = data.map(record => ({
                    ...record,
                    formattedTimestamp: this.formatDate(record.Timestamp__c),
                    shortMessage: record.Message__c ? record.Message__c.substring(0, 100) + '...' : '',
                }));
                for (let i = 0; i < this.records.length; i++) {
                    this.records[i].Id = i;
                }
                this.filteredRecords = [...this.records];
                this.lastTimestamp = data[data.length - 1].Timestamp__c;
            } else {
                // Limpieza si no hay datos
                this.records = [];
                this.filteredRecords = [];
                this.lastTimestamp = null;
            }
        })
        .catch(error => {
            console.error('Error en fetchRecords:', error);
            // También limpiamos en caso de error para evitar datos inconsistentes
            this.records = [];
            this.filteredRecords = [];
            this.lastTimestamp = null;
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    loadMoreRecords() {
        this.fetchRecords();
    }

    connectedCallback() {
        this.setDefaultDates();
        this.fetchRecords();
    }

    setDefaultDates() {
        const today = new Date();
        const firstDay = new Date(today.getFullYear(), today.getMonth(), 1).toISOString().split('T')[0];
        const lastDay = new Date(today.getFullYear(), today.getMonth() + 1, 0).toISOString().split('T')[0];

        if (!this.searchTimestampFrom) {
            this.searchTimestampFrom = firstDay;
        }
        if (!this.searchTimestampTo) {
            this.searchTimestampTo = lastDay;
        }
    }

    handleFilterChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value.trim().toLowerCase();
        this.applyFilters();
    }

    applyFilters() {
        this.filteredRecords = this.records.filter(record => {
            return (
                (this.projectFilter === '' || (record.Project__c && record.Project__c.toLowerCase().includes(this.projectFilter))) &&
                (this.typeFilter === '' || (record.Type__c && record.Type__c.toLowerCase().includes(this.typeFilter))) &&
                (this.classFilter === '' || (record.Class_Name__c && record.Class_Name__c.toLowerCase().includes(this.classFilter))) &&
                (this.methodFilter === '' || (record.MethodName__c && record.MethodName__c.toLowerCase().includes(this.methodFilter)))
            );
        });
    }

    formatDate(timestamp) {
        if (!timestamp) return '';
        const date = new Date(timestamp);
        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const year = date.getFullYear();
        const hours = String(date.getHours()).padStart(2, '0');
        const minutes = String(date.getMinutes()).padStart(2, '0');
        const seconds = String(date.getSeconds()).padStart(2, '0');
        return `${day}/${month}/${year} ${hours}:${minutes}:${seconds}`;
    }

    handleDownload(event) {
        const recordId = event.target.dataset.id;
        //const record = this.records.find(rec => rec.Id === recordId);
        let record = this.filteredRecords.find(rec => rec.Id == recordId) ||
        this.records.find(rec => rec.Id == recordId);
        if (record) {
            const { StackTrace__c, Object__c, LineNumber__c, DML_Fields__c, DML_StatusCode__c, ...visibleData } = record;
            //const jsonData = JSON.stringify({ ...visibleData, StackTrace__c, Object__c, LineNumber__c, DML_Fields__c, DML_StatusCode__c }, null, 2);
            const jsonData = JSON.stringify({
                Timestamp__c: record.Timestamp__c,
                Project__c: record.Project__c,
                Type__c: record.Type__c,
                Class_Name__c: record.Class_Name__c,
                MethodName__c: record.MethodName__c,
                Message__c: record.Message__c, // ✅ Mensaje completo
                StackTrace__c: record.StackTrace__c || 'N/A',
                Object__c: record.Object__c || 'N/A',
                LineNumber__c: record.LineNumber__c || 'N/A',
                DML_Fields__c: record.DML_Fields__c || 'N/A',
                DML_StatusCode__c: record.DML_StatusCode__c || 'N/A'
            }, null, 2);
            const blob = new Blob([jsonData], { type: 'text/plain' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'record_'+record.Timestamp__c+'_'+record.MethodName__c+'.txt';
            a.click();
            URL.revokeObjectURL(url);
        }
    }
}