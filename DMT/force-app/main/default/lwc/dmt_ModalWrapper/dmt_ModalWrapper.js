import { LightningElement, api } from 'lwc';

export default class dmt_ModalWrapper extends LightningElement {
    
    @api headerTitle = 'Ventana Modal';

    handleClose() {
        // Dispara un evento simple 'close' que el padre escuchará
        this.dispatchEvent(new CustomEvent('close'));
    }
}