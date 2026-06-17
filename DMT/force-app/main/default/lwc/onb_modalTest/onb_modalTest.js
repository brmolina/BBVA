import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class Onb_modalTest extends LightningModal {
    @api header = 'Header de PRUEBA';
    @api hideFooter = false;

    get showFooter() {
        return !this.hideFooter;
    }
}