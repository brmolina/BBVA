import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
export default class Dmt_showPopover extends LightningElement {

    @api header = 'Default Title';
    @api message = 'Default Message';
    @api messageTitle;
    @api variant; // info, success, warning, error
    @api mode = 'dismissable'; // dismissable, pester, sticky
    error = false;
    success = false;
    info = false;
    warning = false;
    showPopovervalue;
    showError = true;
    showWarning = true;

    // @api
    // get  title() {
    //     return this.title;
    //   }
    
    // set title(value) {
    //   this.title = value;
    // }
    @api
     get  showPopover() {
         return this.showPopovervalue;
       }
    
     set showPopover(value) {
        console.log('*** Values to error cmp' ,value);
        this.error = this.variant === 'error';
        this.success = this.variant === 'success';
        this.info = this.variant === 'info';
        this.warning = this.variant === 'warning';
        console.log('***VALUE error ',value);
        if(value && !value.toString().startsWith('{') && !value.toString().endsWith('}')){
            this.showPopovervalue = value;
            console.log('92',this.template.querySelector('div'))
            if( this.template.querySelector('div') !==null && this.message.length > 47){console.log('ul',this.message.length);
                this.template.querySelector('div').style.marginTop = '-1.35em';
            }
        }
        //this.showPopovervalue = 'test';
     }

    @api
    get  variantMode() {
      return this.variant;
    }
  
    set variantMode(value) {
        this.variant = value;
        this.error = this.variant === 'error';
        this.success = this.variant === 'success';
        this.info = this.variant === 'info';
        this.warning = this.variant === 'warning';

    }

    renderedCallback(){
        if(this.variant){
            this.error = this.variant === 'error';
            this.success = this.variant === 'success';
            this.info = this.variant === 'info';
            this.warning = this.variant === 'warning';console.log('error',this.success);
        }
    }

    handleShowToast() {console.log("estoy en el handle",this.messageDataLink0+'/'+this.messageSObject0 +'/'+this.messageRecord0);
    console.log("estoy en el message",this.message);
        const toastEvent = new ShowToastEvent({
            title: this.title,
            message: this.message,
            variant: this.variant,
            mode: this.mode,
            messageData: [
                this.messageData0,
                this.messageData1,
                {
                    url: this.messageDataLink0+'/'+this.messageSObject0 +'/'+this.messageRecord0,
                    label: this.messageLabel0,
                },
                {
                    url: this.messageDataLink1+'/'+this.messageSObject1 +'/'+this.messageRecord1,
                    label: this.messageLabel1,
                }
            ]
        });
        this.dispatchEvent(toastEvent);
    }
    onClickClose(event){
        if(this.error){
            this.showError = false;
        }
        if(this.warning){
            this.showWarning = false;
        }
    }

    onClickIcon(event){
        if(this.error){
            this.showError = true;
        }
        if(this.warning){
            this.showWarning = true;
        }
    }


}