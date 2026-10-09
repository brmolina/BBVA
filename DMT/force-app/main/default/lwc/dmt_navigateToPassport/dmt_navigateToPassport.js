import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getInformationPassport from '@salesforce/apex/DMT_Passport_Handler.getInformationPassport';

export default class Dmt_navigateToPassport extends NavigationMixin(LightningElement) {
    @api recordid;
    @api buttonLabel = 'Detail';
    @api iconName = 'utility:expand_alt';

    passportId;

    @wire(getInformationPassport, { recordId: '$recordid' })
    wiredInformationPassport({ error, data }) {
        if (data) {
            try {
                const dataParse = JSON.parse(data);
                this.passportId = dataParse.passportId;
            } catch (e) {
                this.handleError(e);
            }
        } else if (error) {
            this.handleError(error);
        }
    }

    handleError(error) {
        console.error('Error obteniendo el passportId: ', JSON.stringify(error));

        let message = 'Ha ocurrido un error inesperado al obtener el pasaporte.';
        if (typeof error?.body?.message === 'string') {
            message = error.body.message;
        } else if (typeof error === 'string') {
            message = error;
        }

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message,
                variant: 'error'
            })
        );
    }

    get isDisabled() {
        return !this.passportId;
    }

    handleOpenNavigation() {
        if (!this.passportId) return;
        console.log('OPEN NAV passportId:', this.passportId, 'prefix:', String(this.passportId).substring(0, 3));
        
        const pageReference = {
            type: 'standard__recordPage',
            attributes: {
                recordId: this.passportId,
                objectApiName: 'Passport__c',
                actionName: 'view'
            }
        };

        this[NavigationMixin.GenerateUrl](pageReference)
            .then((url) => {
                const link = document.createElement('a');
                link.setAttribute('href', url);
                link.setAttribute('target', '_blank');
                link.setAttribute('rel', 'noopener noreferrer');
                link.style.visibility = 'hidden';
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
            })
            .catch((error) => this.handleError(error));
    }
}