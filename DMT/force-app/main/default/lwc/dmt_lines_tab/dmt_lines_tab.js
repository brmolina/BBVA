import { LightningElement, api, wire, track } from 'lwc';
import checkReadPermission from '@salesforce/apex/DMT_LineController.checkReadPermission';
import hasLineGodPermission from '@salesforce/customPermission/DMT_Line_God';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { 
    getRecord,
    getFieldValue,
    getRecordNotifyChange,
    updateRecord,
    notifyRecordUpdateAvailable} from 'lightning/uiRecordApi';
import LINE_ID from "@salesforce/schema/DMT_Line__c.Line_Id__c";
import LINE_TYPE from "@salesforce/schema/DMT_Line__c.DMT_line_template_type__c";
import LINE_STATUS from "@salesforce/schema/DMT_Line__c.Status__c";
import LINE_CURRENCY from "@salesforce/schema/DMT_Line__c.CurrencyIsoCode";
import LINE_LOCK from "@salesforce/schema/DMT_Line__c.DMT_Line_Lock__c";
import LINE_DELETED from "@salesforce/schema/DMT_Line__c.DMT_Deleted__c";
import USER_ID_FIELD from '@salesforce/schema/User.Id';
import CURRENT_USER_ID from '@salesforce/user/Id';
import CURRENT_USER_NAME from '@salesforce/schema/User.Name';
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent } from "lightning/refresh";
import pubsub from 'omnistudio/pubsub';


export default class Dmt_lines_tab extends LightningElement {
@track recordId;
@track lineStatus;
@track lineCurrency;
isViewDisabled = true;
lineData;
treasuryTemplate;
updateKey = 0;
refreshTrigger = 0;
selectedTab = 'lineinfo'
editingTab;
userName;
lineDeleted;
isLoading = true;
isLockedByOther = false;
isLockEditing = false;
@track userLock;
wiredLineResult;
@track lineFields = [LINE_ID, LINE_TYPE, LINE_STATUS, LINE_CURRENCY, LINE_LOCK];
modalMessage;

optionsTab = {
    lineinfo: 'Line Info',
    client: 'Client',
    clientlegacy: 'Client Legacy',
    products: 'Products',
    participants: 'Participants',
    approvalprocessdata: 'Approval Process Data'
};

get currentUserId() {
    return CURRENT_USER_ID; // Esto ya viene de '@salesforce/user/Id'
}

get isLockedByOther() {
        return this.lineLock && this.lineLock != this.currentUserId;
}

connectedCallback(){
    
    // Agregar listener para cierre/recarga
    window.addEventListener('beforeunload', this.handleBeforeUnload.bind(this));
}

renderedCallback(){
    // Limpiar listener cuando el componente se destruya
    window.removeEventListener('beforeunload', this.handleBeforeUnload.bind(this));
    if( this.userLock == this.currentUserId) {
                  updateRecord({ fields: { 
                    Id: this.recordId,
                    DMT_Line_Lock__c: null
                    }});  
                }
    this.handleCheckEditPermission();  
}

    handleBeforeUnload(event) {
        if (this.editingTab != null) {
            // Mensaje personalizado (la mayoría de navegadores muestran su propio mensaje)
            const message = 'You have unsaved changes! Are you sure you want to exit?';
            
            // Para navegadores modernos
            event.preventDefault();
            event.returnValue = message;
            
            // Llamar a tu método para limpiar el registro
            this.releaseRecordLock();
            
            return message;
        }
    }

@wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {            
            // Check standard and custom state parameters
            this.recordId = currentPageReference.state?.recordId || currentPageReference.state?.c__recordId || currentPageReference.attributes?.recordId;
            this.lineId = this.recordId;
        }
    }

    get clientColumns() {
        return [
            [{fieldName: 'Client__c', isReadOnly: true}],
                [{fieldName: 'Client_Type__c', isReadOnly: true}]
        ];
    }

    @wire(getRecord, { recordId: '$lineId', fields: [LINE_ID, LINE_TYPE, LINE_STATUS, LINE_CURRENCY, LINE_LOCK, LINE_DELETED] })
        wiredRecord(result) {
            this.dispatchEvent(new RefreshEvent());
            this.wiredLineResult = result;
            const { error, data } = result;
             if (data) {
                this._lineData = data;
                const nextLineStatus = getFieldValue(data, LINE_STATUS);
                const nextLineCurrency = getFieldValue(data, LINE_CURRENCY);
                const lineContextChanged =
                    (this.lineStatus != null && this.lineStatus !== nextLineStatus) ||
                    (this.lineCurrency != null && this.lineCurrency !== nextLineCurrency);
                
                this.treasuryTemplate = getFieldValue(data, LINE_TYPE) == 'TL' ? true : false;
                this.lineDeleted = getFieldValue(data, LINE_DELETED);
                
                this.userLock = getFieldValue(data, LINE_LOCK);
                this.lineStatus = nextLineStatus;
                this.lineCurrency = nextLineCurrency;

                if (lineContextChanged) {
                    this.handleCheckEditPermission();
                    const clientComponent = this.template.querySelector('c-dmt-select-clients-in-line-migrated');
                    if (clientComponent) {
                        clientComponent.refreshLineContext({
                            lineStatus: this.lineStatus,
                            currency: this.lineCurrency
                        });
                    }
                    this.updateKey += 1;
                    pubsub.fire("linestab", "refresh", {  });
                }

                if ( this.userLock != null && this.userLock != this.currentUserId) {
                    var tabs = this.template.querySelectorAll("lightning-tab");
                    for (let i = 0; i < tabs.length; i++) {
                        tabs[i].classList.add('isEditing');
                    }
                    
                }
            } else if (error) {
                    this.showToast('Error loading line information', error.body ? error.body.message : error.message, 'error');
            }
        }

    @wire(getRecord, { recordId: '$userLock', fields: [CURRENT_USER_NAME]})
        wiredUser({ error, data }) {
            if (data) {
               this.userName = data.fields.Name.value;
           } else if (error) {
                   this.showToast('Error loading user information', error.body ? error.body.message : error.message, 'error');
           }
    }

handleCheckEditPermission() {

    if (hasLineGodPermission) {
        this.isViewDisabled = false;
        this.isLoading = false;
        return;
    } 
    checkReadPermission({ recordId: this.recordId })
        .then((result) => {
        const { isAdmin, accessLevel_read } = result;
            this.isViewDisabled = !(isAdmin || accessLevel_read) || this.lineDeleted;
            this.isLoading = false;
        })
        .catch((error) => {
            this.isLoading = false;
            console.error('Error determining permission:', error);
    });
}
//  async handleRefresh(){
//      this.wiredLineResult = [];
//      await notifyRecordUpdateAvailable([{ recordId: this.recordId}]);
//      await refreshApex(this.wiredLineResult);
//  }

handleEditing(event) {
    refreshApex(this.wiredLineResult).then(() => {
    this.editingTab = event.detail.tab;
    if ( this.userLock && this.userLock != null && this.userLock != this.currentUserId) {
        pubsub.fire("linestab", "refresh", {  });
        this.modalMessage = 'This line is currently being edited by '+ this.userName;
        this.isLockedByOther = true;
        this.editingTab = null;
    } else {
        // Bloquear el registro
        const lineLock = event.detail.tab == null ? null : this.currentUserId;
        updateRecord({ fields: { 
            Id: this.recordId,
            DMT_Line_Lock__c: lineLock
        }});
        }
    })

}

releaseRecordLock() {
    updateRecord({ fields: { 
        Id: this.recordId,
        DMT_Line_Lock__c: null
        }});
    }

async handleRetry() {
        //this.isLoading = true;
        try {
            // Esto fuerza a que el @wire(getRecord) se ejecute de nuevo

            this.isLockedByOther = false;
            this.isLockEditing = false;
        
        } catch (error) {
            this.showToast('Error', 'No se pudo actualizar el estado de bloqueo', 'error');
        } finally {
            //this.isLoading = false;
        }
    }

showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            variant: variant,
            message: message,
            mode: 'dismissable'
        }));
}

handleClickTab(event){
    if ( this.editingTab != null && event.target.value != this.editingTab) {
        this.template.querySelector('lightning-tabset').activeTabValue = this.editingTab;
        this.modalMessage = 'There is an edit in progress in the ' +this.optionsTab[this.editingTab]+ ' tab. Please finish editing to switch tabs.';
        this.isLockEditing = true;
        
    }
}

handleClickPath(event){
    if( this.editingTab != null){
        this.modalMessage = 'There is an edit in progress in the ' +this.optionsTab[this.editingTab]+ ' tab. Please finish editing to update Status.';
        this.isLockEditing = true;
    }
}

}