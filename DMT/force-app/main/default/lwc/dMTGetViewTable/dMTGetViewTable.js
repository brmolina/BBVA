import { LightningElement, api } from 'lwc';

export default class dMTGetViewTable extends LightningElement {
    @api views;
    selectedViewId;

    columns = [
        { label: 'View Name', fieldName: 'Name' },
        { label: 'Marco de Linea', fieldName: 'DMT_MarcoLinea__c' },
        { label: 'Marco de Producto', fieldName: 'DMT_MarcoProducto__c' },
        { label: 'Marco de Cliente', fieldName: 'DTM_marcoCliente__c' }
    ];

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 0) {
            this.selectedViewId = selectedRows[0].Id;
            this.dispatchEvent(new CustomEvent('viewselect', {
                detail: { viewId: this.selectedViewId }
            }));
        }
    }
}