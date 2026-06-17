import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class Onb_confirmMassFundProductToggle extends LightningModal {
    @api header;
    @api message;
    @api confirmLabel = 'Confirm';
    @api cancelLabel = 'Cancel';

    handleCancel() {
        this.close({ confirmed: false });
    }

    handleConfirm() {
        this.close({ confirmed: true });
    }
}