import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import LightningPrompt from "lightning/prompt";
import LightningAlert from 'lightning/alert';

export default class ToastComponent extends LightningElement {
    @api title = 'Default Title';
    @api message = 'Default Message';
    @api variant = 'info'; // info, success, warning, error
    @api mode = 'dismissable'; // dismissable, pester, sticky
    sendToast;
    @api showPrompt;

    @api
    get  sendToastFire() {
      return this.sendToast;
    }
  
    set sendToastFire(value) {
        if(value.toLowerCase() === 'true'){
                this.handleShowToast();
                this.sendToast = value;

        }
        this.sendToast = false;
    }

    handleShowToast() {
        const toastEvent = new ShowToastEvent({
            title: this.title,
            message: this.message,
            variant: this.variant,
            mode: this.mode
        });
        this.dispatchEvent(toastEvent);
    }

    handlePromptClick() {
        if(this.showPrompt){
        LightningAlert.open({
            message: this.message,
            theme: this.variant, 
            label: this.title, 
            variant: 'header',
        });
      }
    }
}