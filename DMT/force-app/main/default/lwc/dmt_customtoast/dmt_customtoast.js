import { LightningElement, api, track } from 'lwc';

export default class Dmt_customtoast extends LightningElement {
    @track isShown = false;
    @track title = '';
    @track message = '';
    @track variant = 'info';

    // Configuración por defecto
    autoCloseTime = 5000;

    get toastClass() {
        return `slds-notify slds-notify_toast slds-theme_${this.variant}`;
    }

    get iconName() {
        switch(this.variant) {
            case 'success': return 'utility:success';
            case 'error': return 'utility:error';
            case 'warning': return 'utility:warning';
            default: return 'utility:info';
        }
    }

    get iconClass() {
        return `slds-icon_container slds-icon-utility-${this.variant} slds-m-right_small slds-no-flex slds-align-top`;
    }

    @api
    showToast(title, message, variant = 'info', autoClose = true) {
        this.title = title;
        this.message = message;
        this.variant = variant;
        this.isShown = true;

        if (autoClose) {
            // Limpiar timeout anterior si existe para evitar conflictos
            if(this.delayTimeout) clearTimeout(this.delayTimeout);

            this.delayTimeout = setTimeout(() => {
                this.closeToast();
            }, this.autoCloseTime);
        }
    }

    closeToast() {
        this.isShown = false;
    }
}