import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

import surveyNotification from '@salesforce/apex/DES_cls_BotonNoteBookLm.surveyNotification';

export default class DES_lwc_BotonNoteBookLm extends LightningElement {
    
    @api label = 'HELP';
    @api title = 'HELP';
    @api url = 'https://notebooklm.google.com/notebook/d1c45063-ef3b-41e1-8244-5403ba1f5b1f?addSource=true';
    @api surveyName = 'SupportWUT';
    @api isNotQuickAction = false;
    
    @api variant;
    @api iconName;
    @api iconPosition = 'left';
    
    @api openInNewTab = false;
    @api disabled = false;
    
    @api showSuccessToast = false;
    @api showErrorToast = false;
    @api moduleName;
    isBusy = false;
    
    get computedDisabled() {
        return this.disabled || this.isBusy; 
    } 
    
    get computedTitle() {
        return this.title || this.label; 
    } 
    
    connectedCallback() {
        if(!this.isNotQuickAction) {
            this.openInNewTab = true;
            this.handleClick();
        }       
    }
    
    
    async handleClick() {
        
        this.isBusy = true; 
        
        try {
            if (this.openInNewTab) {
                this.publishEvent();
                
                if(!this.isNotQuickAction) {
                    setTimeout(() => {
                        this.dispatchEvent(new CloseActionScreenEvent());
                    }, 100);
                }
                
                window.open(this.url, '_blank', 'noopener,noreferrer');    
            } else {
                this.publishEvent(); 
                window.open(this.url, '_self', 'noopener,noreferrer'); 
            } 
        } finally {
            
            this.isBusy = false; 
        } 
    } 
    
    publishEvent() {
        
        surveyNotification({
                survey: this.surveyName,
                moduleName: this.moduleName
            }).then( data => {
            if(this.showSuccessToast) {
                this.toast('Event Complete','', 'success');
            }
        }).catch((error) => {
            console.error('Error fetching fields:', JSON.stringify(error));
            if(this.showErrorToast) {
                this.toast('Publish Event','Please review publish Event', 'error'); 
            }
        });
    } 
    
    toast(title, message, variant) {
        this.dispatchEvent( new ShowToastEvent({
            title, message, variant 
        }) ); 
    } 
}