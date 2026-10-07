import { LightningElement, api, track, wire } from 'lwc';
import { updateRecord, getRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import updateTask from '@salesforce/apex/DMT_Case_Steps_Controller.updateTask';

export default class Dmt_textField extends LightningElement {
    @api label;
    @api recordId;
    @api fieldName; // API name del campo
    @api fieldType = 'textarea'; // text, email, tel, url, textarea, rich
    @api placeholder;
    @api required = false;
    @api disabled = false;
    @api maxLength;
    @api rows = 6; // para textarea
    @api variant = 'label-stacked';
    @api objectApiName;
    @track value; // label-stacked, label-inline, label-hidden
    @track textareaCharCount = 0;
    _action;
    _isUserEditing = false;
    _fieldApiNames;
    _fieldApiNamesKey;


    get fieldReference() {
        return { fieldApiName: this.fieldName,
            objectApiName: this.objectApiName
         };
    }

    @api
    get action() {
        return this._action;
    }

    normalizeValue(value) {
        if ( value === 'null') {
            return '';
        }
        return value;
    }

    set action(value) {
        this._action = value;
        // Convertir null/undefined a string vacío
        console.log('value before'+value);
        if (value == 'save') {
            let fields = {
                Id: this.recordId
            }
            fields[this.fieldName] = this.normalizeValue(this.value);
            console.log('fields to update:', JSON.stringify(fields));
            if( fields.Id ){
                console.log('fobjApiName:', this.objectApiName);
                if (this.objectApiName === 'Task') {
                    console.log('Updating Task:', JSON.stringify(fields));
                    
                    updateTask({ 
                        taskId: this.recordId, 
                        fieldsToUpdate: fields 
                    })
                    .then(() => {
                        this._isUserEditing = false;
                        return notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
                    })
                    .catch(error => {
                        console.error('Error updating Task:', JSON.stringify(error));
                    });
                } else {
                updateRecord({ fields })
                    .then(() => {
                        this._isUserEditing = false;
                        return notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
                    })
                    .catch(error => {
                        console.error('Error updating record:', JSON.stringify(error));
                    });
                }
            }

        }
    }

    get isRichText() {
        return this.fieldType === 'rich';
    }

    get isTextarea() {
        return this.fieldType === 'textarea';
    }

    get inputType() {
        // Mapeo de tipos personalizados a tipos de lightning-input
        const typeMap = {
            'text': 'text',
            'email': 'email',
            'tel': 'tel',
            'url': 'url',
            'textarea': 'textarea',
            // Para rich text usamos un componente diferente
        };
        return typeMap[this.fieldType] || 'text';
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$fieldApiNames' })
    wiredRecord({ error, data }) {
        if (data) {
            try {
                if (this._isUserEditing) {
                    return;
                }
                const rawValue = data.fields[this.fieldName]?.value;
                this.value = this.normalizeValue(rawValue);
                this.updateTextareaState(this.value);
                this.error = undefined;
            } catch (e) {
                this.error = `Error retrieving field: ${this.fieldName}`;
                console.error(e);
                this.value = undefined;
            }
        } else if (error) {
            this.error = this.formatError(error);
            this.value = undefined;
        }
    }

    get fieldApiNames() {
        const key = `${this.objectApiName}.${this.fieldName}`;
        if (this._fieldApiNamesKey === key && this._fieldApiNames) {
            return this._fieldApiNames;
        }

        if (this.fieldName) {
            this._fieldApiNames = [this.objectApiName+".Id", this.objectApiName+"."+this.fieldName];
            this._fieldApiNamesKey = key;
            return this._fieldApiNames;
        }
        this._fieldApiNames = [this.objectApiName+".Id"];
        this._fieldApiNamesKey = key;
        return this._fieldApiNames;
    }
    
    formatError(error) {
        if (error.body) {
            return error.body.message || error.body.pageErrors?.[0]?.message;
        }
        return 'Unknown error loading the record';
    }
    handleChange(event) {
        // Obtener el valor, asegurando que null/undefined se conviertan a string vacío
        let newValue = event.detail?.value;
        
        // Si es rich text, el valor viene diferente
        if (this.isRichText) {
            newValue = event.target?.value || event.detail?.value;
        } else {
            newValue = event.detail?.value|| event.target?.value
        }

        newValue = this.normalizeValue(newValue);

        if (this.isTextarea) {
            this.textareaCharCount = newValue ? newValue.length : 0;
        }

        // Actualizar el valor interno
        this._isUserEditing = true;
        this.value = newValue;
        this.updateTextareaState(this.value);
        console.log(' this.value: ',  this.value);
        const valueChangeEvent = new CustomEvent('textfieldchange', {
            detail: {
                fieldName: this.fieldName,
                value: newValue,
                fieldType: this.fieldType,
                label: this.label
            },
            bubbles: true,
            composed: true
        });
        
        this.dispatchEvent(valueChangeEvent);
    }

    handleInput(event) {
        this.handleChange(event);
    }

    // Para componentes que no disparan el evento estándar
    handleBlur(event) {
        if (this.isRichText) {
            this.handleChange(event);
        }
    }

    get computedMaxLength() {
        return this.maxLength ? parseInt(this.maxLength, 10) : undefined;
    }

    get computedTextareaMaxLength() {
        const parsed = parseInt(this.maxLength, 10);
        return Number.isFinite(parsed) && parsed > 0 ? parsed : 500;
    }

    get textareaCounterClass() {
        return 'textarea-counter slds-text-body_small';
    }

    updateTextareaState(value) {
        if (!this.isTextarea) {
            return;
        }

        this.textareaCharCount = value ? value.length : 0;
    }
}