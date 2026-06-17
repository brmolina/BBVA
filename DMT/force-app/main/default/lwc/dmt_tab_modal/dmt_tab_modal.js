import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class Dmt_tab_modal extends LightningModal {

    @api modalLabel;
    @api modalContent;
    handleClose() {
        this.close('modal closed');
    }
}