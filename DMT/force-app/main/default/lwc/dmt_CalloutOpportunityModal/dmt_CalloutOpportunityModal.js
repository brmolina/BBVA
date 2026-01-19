import LightningModal from 'lightning/modal';
import { api } from 'lwc';

export default class Dmt_CalloutOpportunityModal extends LightningModal {

    @api oppId;
    @api customerId;

    handleCancel() {
        this.close();
    }

    handleSave(event) {
        this.close(event.detail);
    }
}