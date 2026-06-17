import { api} from 'lwc';
import LightningModal from 'lightning/modal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { processAndCreateContact } from 'c/onb_contactUtils';

const RELATIONSHIP_CONTACTS_TYPE = 'RELATIONSHIP_CONTACTS';

export default class Onb_createContactModal extends LightningModal {

    title = 'New Contact';
    @api recordId;
    @api header;
    @api footer;

    contactFormFieldsLeft = ['FirstName', 'LastName'];
    contactFormFieldsRight = ['MailingStreet', 'Email_ExternalID__c'];

    customLabels = {
        'MailingStreet': 'Address',
        'Email_ExternalID__c': 'Email'
    };

    collectedValues = {};

    get showFooter() {
        return this.footer;
    }

    reglasValidacion = {
        'FirstName': { required: true },
        'LastName': { required: true },
        'Email_ExternalID__c': { required: true }
    };

    handleValueChange(event) {
        const fieldName = event.detail.fieldApiName;
        const value = event.detail.value;
        this.collectedValues[fieldName] = value;
    }

    async handleCreateContact() {
        //Validar que no falten datos en NINGUNO de los dos formularios
        const formularios = this.template.querySelectorAll('c-onb_onboarding-form');
        let todosValidos = true;

        formularios.forEach(form => {
            if (!form.validate()) {
                todosValidos = false;
            }
        });

        if (!todosValidos) return; // Nos detenemos para que el usuario corrija los campos en rojo

        const result = await processAndCreateContact(this, this.collectedValues, this.recordId, RELATIONSHIP_CONTACTS_TYPE);

        if (result.success) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: 'Contact created successfully', variant: 'success' }));
            //Autodestruir el Modal y mandar el ID del contacto a la tabla original
            this.close({ action: 'create', payload: { contactId: result.contactId } });
        }
    }
}