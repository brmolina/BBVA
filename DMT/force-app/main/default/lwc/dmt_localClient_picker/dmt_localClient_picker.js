import { LightningElement, api, track } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

export default class LocalClientPicker extends LightningElement {

    @api clientId;
    @api mitangt;
    _entityId;
    filter={};
    disabled=false;

    @api
    get entityId() {
        return this._entityId;
    }

    set entityId(value) {
        this._entityId = value;
        console.log('ABS Entity value:'+value);

    if (value === null || value === undefined || value === '' || value === 'null' || value === 'undefined') {
        console.log('ABS entra en if filter null');
        this.filter = null;
        return;
    }

    this.filter = {
        criteria: [
            {
                fieldPath: 'Alpha_code__c',
                operator: 'like',
                value: '%' + value + '%'
            },

            {
                fieldPath: 'DMT_ID_Fiscal__c',
                operator: 'like',
                value: '%' + value + '%'
            }
        ],
        filterLogic: '1 OR 2'  
    };
    }

    matchingInfo = {
        primaryField: { fieldPath: 'Name' },
        additionalFields: [{ fieldPath: 'Alpha_code__c' }]
    }

    displayInfo = {
        primaryField: 'Name',
        additionalFields: ['Alpha_code__c']
    };

    get hasValue() {
        return this.clientId && this.clientId !== '' && this.clientId !== 'null' && this.clientId !== 'undefined';
    }

    get hasValueEntity() {
        console.log('ABS hasValue '+ this.entityId && this.entityId !== '' && this.entityId !== 'null' && this.entityId !== 'undefined');
        return this.entityId && this.entityId !== '' && this.entityId !== 'null' && this.entityId !== 'undefined';
    }
    get labelValue() {
        if(this.mitangt) {
            return 'Select Guarantor';
        } else {
            return 'Local Client';
        }
    }
    get placeholderValue() {
        if(this.mitangt) {
            return 'Search Guarantor...';
        } else {
            return 'Search Clients...';
        }
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