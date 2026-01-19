import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfo, getRecord } from 'lightning/uiObjectInfoApi';
import getAllRecords from '@salesforce/apex/DMT_CustomListViewController.getAllRecords';
import { getListUi } from 'lightning/uiListApi';

export default class CustomListView extends LightningElement {
    @api objectApiName;
    tableKey = '';
    @track columns = [];
    @track availableFields = [];
    @track records = [];
    @track filteredRecords = [];
    @track searchTerm = '';
    @track selectedColumns = [ {label: 'Name', fieldName: 'name'} ]; 
    configcolumns = [];
    @track allFields = []; // Array de todos los campos con sintaxis Object.Field

    @track showColumnPanel = false; // Para panel de selección de columnas

    refreshTable(){
        this.tableKey = Date.now();
    }

    // Obtener campos del objeto
    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    wiredObjectInfo({ data, error }) {
        if (data) {
            this.objectFields = Object.keys(data.fields);console.log('object',JSON.stringify(this.objectFields));
            this.availableFields = data.fields;
            this.allFields = Object.keys(data.fields).map(f => `${this.objectApiName}.${f}`);
            // Columnas por defecto: Name si existe
            this.objectFields.forEach(f => {
                this.columns.push({ label: this.availableFields[f].label, fieldName: this.availableFields[f].apiName.toLowerCase() });
                this.configcolumns.push({ label: this.availableFields[f].label, value: this.availableFields[f].apiName.toLowerCase() });
            });console.log('colums',JSON.stringify(this.columns));

        } else if (error) {
            console.error('Error cargando campos:', error);
        }
    }

    // Obtener registros de la lista 'All'
    @wire(getAllRecords, { objectApiName: '$objectApiName' })
    wiredRecords({ data, error }) {
        if (data) {
            this.records = data;console.log('record',JSON.stringify(this.records));
            this.filteredRecords = [...this.records];

            // Generar columnas dinámicamente
            // if (data.length > 0) {
            //     this.columns = Object.keys(data[0]).map(field => ({
            //         label: field,
            //         fieldName: field
            //     }));
            // }
        } else if (error) {
            console.error('Error cargando registros:', error);
        }
    }

    // Búsqueda rápida
    handleSearch(event) {
        this.searchTerm = event.target.value.toLowerCase();
        this.filteredRecords = this.records.filter(r =>
            r.values.some(v => (v + '').toLowerCase().includes(this.searchTerm))
        );
    }

    // Mostrar u ocultar panel de columnas
    toggleColumnPanel() {
        this.showColumnPanel = !this.showColumnPanel;
    }

    // Cambiar columnas visibles desde dual-listbox
    handleColumnChange(event) {
        const selectedFields = event.detail.value;console.log('event',selectedFields[0]); // array de API Names
        const selectColumns =  [ {label: 'Name', fieldName: 'name'} ]; 
        selectedFields.forEach(f => {
            selectColumns.push( ({ label: f, fieldName: f }));
        });
        this.selectedColumns = [...this.selectColumns];
        refreshTable();
        // Remapear los registros
        // this.filteredRecords = this.records.map(r => {
        //     const values = this.columns.map(col => r.values[this.availableFields.indexOf(col.fieldName)] || '');
        //     return { Id: r.Id, values };
        // });
    }
}