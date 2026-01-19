import { LightningElement, api, track } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

export default class LocalClientPicker extends LightningElement {

    @api clientId;
    _entityId;
    filter={};
    disabled=false;

    @api
    get entityId() {
        return this._entityId;
    }

    set entityId(value) {
        this._entityId = value;

    if (value === null || value === undefined || value === '' || value === 'null' || value === 'undefined') {
        this.filter = null;
        return;
    }

        this.filter = {
            criteria: [
                {
                    fieldPath: 'Alpha_code__c',
                    operator: 'like',
                    value: '%' + value + '%'
                }
            ]
        };
    }

    matchingInfo = {
        primaryField: { fieldPath: 'Name' },
        additionalFields: [{ fieldPath: 'Alpha_code__c' }]
    }

    displayInfo = {
        primaryField: 'Name'
    };

get hasValue() {
    return this.clientId && this.clientId !== '' && this.clientId !== 'null' && this.clientId !== 'undefined';
}

    get hasValueEntity() {
        return this.entityId && this.entityId !== '' && this.entityId !== 'null' && this.entityId !== 'undefined';
    }

connectedCallback() {
    if (!this.clientId) {
        this.clientId = null;
    }
}

handleChange(event) {
    try {
        // Aquí sí viene el recordId en event.detail.recordId
        const recordId = event.detail.recordId;

        // Creamos el evento personalizado con el ID del registro
        const selectedEvent = new CustomEvent('recordselected', {
            bubbles: true,
            composed: true,
            detail: { recordId: recordId }
        });

        this.dispatchEvent(selectedEvent);
        
        const attributeChangeEventclientId = new FlowAttributeChangeEvent('clientId', recordId);
        this.dispatchEvent(attributeChangeEventclientId);        
    } catch (e) {
            console.error('Error in the handleChange LocalClientPicker:', e);
    }
}
}