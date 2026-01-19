import { LightningElement, api, wire } from 'lwc';
import checkEditPermission from '@salesforce/apex/DMT_LineController.checkReadPermission';
import hasLineGodPermission from '@salesforce/customPermission/DMT_Line_God';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import LINE_ID from "@salesforce/schema/DMT_Line__c.Line_Id__c";
import LINE_TYPE from "@salesforce/schema/DMT_Line__c.DMT_line_template_type__c";
import LINE_STATUS from "@salesforce/schema/DMT_Line__c.Status__c";
import LINE_CURRENCY from "@salesforce/schema/DMT_Line__c.CurrencyIsoCode";

export default class Dmt_lines_tab extends LightningElement {
recordId;
isViewDisabled = true;
lineData;
treasuryTemplate;
updateKey = 0;

connectedCallback(){
    this.handleCheckEditPermission();
}

renderedCallback(){
    console.log('recordId tab',this.recordId)
}

@wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {            
            // Check standard and custom state parameters
            this.recordId = currentPageReference.state?.recordId || currentPageReference.state?.c__recordId || currentPageReference.attributes?.recordId;
        }
    }

    get clientColumns() {
        return [
            [{fieldName: 'Client__c', isReadOnly: true}],
                [{fieldName: 'Client_Type__c', isReadOnly: true}]
        ];
    }

    @wire(getRecord, { recordId: '$recordId', fields: [LINE_ID, LINE_TYPE,LINE_STATUS, LINE_CURRENCY] })
        wiredRecord({ error, data }) {
             if (data) {
                this._lineData = data;
                this.treasuryTemplate = this._lineData.fields.DMT_line_template_type__c.value == 'TL' ? true : false;console.log('treasuryTemplate', this.treasuryTemplate);
                this.updateKey = this.updateKey + 1;
            } else if (error) {
                    this.showToast('Error cargando valores', error.body ? error.body.message : error.message, 'error');
            }
        }

handleCheckEditPermission() {

    if (hasLineGodPermission) {
        console.log('hasLineGodPermission:', hasLineGodPermission);
        this.isViewDisabled = false;
        return;
    } 
    checkEditPermission({ recordId: this.recordId })
        .then((result) => {
        const { isAdmin, accessLevel_read } = result;
            this.isViewDisabled = !(isAdmin || accessLevel_read);
            console.log('isViewDisabled:', this.isViewDisabled);
        })
        .catch((error) => {
            console.error('Error determining button state:', error);
    });
}

}