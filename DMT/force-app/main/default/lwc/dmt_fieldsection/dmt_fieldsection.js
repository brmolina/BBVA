import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class DmtFieldsection extends LightningElement {

    @api recordId;
    @api objectApiName;
    @track isEditMode = false;
    @track processedColumnData = [];

    _columns = [];
    _fieldLabels = {};
    _recordData;

    @api
    get columns() {
        return this._columns;
    }
    set columns(data = []) {
        this._columns = data || [];
    }


    get fieldsForWire() {
        if (!this.objectApiName || !this._columns || this._columns.length === 0) {
            return [];
        }

        const allFieldObjects = this._columns.flat();
        const fieldsToFetch = [];

        allFieldObjects.forEach(obj => {
            const fName = obj.fieldName;
            fieldsToFetch.push(`${this.objectApiName}.${fName}`);

            if (this._fieldLabels && this._fieldLabels[fName]) {
                const meta = this._fieldLabels[fName];
                if (meta.dataType === 'Reference' && meta.relationshipName) {
                    fieldsToFetch.push(`${this.objectApiName}.${meta.relationshipName}.Name`);
                }
            }
        });

        return fieldsToFetch;
    }

    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    wiredObjectInfo({ error, data }) {
        if (data) {
            this._fieldLabels = data.fields;
        } else if (error) {
            this.showToast('Error etiquetas', error.body.message, 'error');
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$fieldsForWire' })
    wiredRecord({ error, data }) {
         if (data) {
            this._recordData = data;
            this.buildViewModel();
        } else if (error) {
            if (this.fieldsForWire.length > 0) {
                this.showToast('Error valores', error.body.message, 'error');
            }
        }
    }

    buildViewModel() {
        if (!this._recordData || !this._fieldLabels || Object.keys(this._fieldLabels).length === 0) {
            return;
        }

        this.processedColumnData = this._columns.map((col, colIndex) => {
            const fieldsInCol = col.map((fieldObject, fieldIndex) => {
                const fName = fieldObject.fieldName;
                const isReadOnly = fieldObject.isReadOnly || false;
                const meta = this._fieldLabels[fName];

                let displayValue = '';

                // --- LÓGICA DE VALOR DE VISUALIZACIÓN ---
                if (meta && meta.dataType === 'Reference' && meta.relationshipName) {
                    displayValue = getFieldValue(this._recordData, `${this.objectApiName}.${meta.relationshipName}.Name`);

                    if (!displayValue) displayValue = '';
                } else {
                    displayValue = getFieldValue(this._recordData, `${this.objectApiName}.${fName}`);
                }

                // Clases CSS
                let viewClasses = 'slds-form-element slds-form-element_readonly';
                if (!isReadOnly) viewClasses += ' slds-form-element_edit slds-hint-parent';

                return {
                    id: `col-${colIndex}-field-${fieldIndex}`,
                    fieldApiName: fName,
                    label: meta ? meta.label : fName,
                    value: displayValue !== null ? displayValue : '',
                    isReadOnly: isReadOnly,
                    viewClasses: viewClasses
                };
            });
            return { id: `col-${colIndex}`, fields: fieldsInCol };
        });
    }

    get columnSize() {
        if (!this._columns || this._columns.length === 0) return 12;
        return 12 / this._columns.length;
    }

    handleEditClick() { this.isEditMode = true; }
    handleCancelClick() { this.isEditMode = false; }
    handleSuccess() {
        this.isEditMode = false;
        this.showToast('Success', 'Fields updated', 'success');
    }
    handleError(event) { this.showToast('Error', event.detail.message, 'error'); }
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}