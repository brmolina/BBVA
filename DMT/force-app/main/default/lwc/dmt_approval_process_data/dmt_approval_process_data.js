import {
    LightningElement,
    api,
    wire,
    track
} from 'lwc';
import {
    refreshApex
} from '@salesforce/apex';
import {
    getRecord,
    getFieldValue,
    getRecordNotifyChange,
    updateRecord,
    notifyRecordUpdateAvailable
} from "lightning/uiRecordApi";
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';
import LINE_TYPE from "@salesforce/schema/DMT_Line__c.Product__c";
import LINE_STATUS from "@salesforce/schema/DMT_Line__c.Status__c";
import LINE_LOCK from "@salesforce/schema/DMT_Line__c.DMT_Line_Lock__c";
import USER_ID from '@salesforce/user/Id';
import getLineLockStatus from '@salesforce/apex/DMT_LineConcurrencyController.getLineLockStatus';
import BOOKING_RISK_ID from "@salesforce/schema/DMT_Line__c.DMT_Booking_Unit_Risk_Analyst__c";
import BOOKING_RISK_NAME from '@salesforce/schema/DMT_Line__c.DMT_Booking_Unit_Risk_Analyst__r.Name';

import APPROVER_ID from "@salesforce/schema/DMT_Line__c.DMT_Approver__c";
import APPROVER_NAME from '@salesforce/schema/DMT_Line__c.DMT_Approver__r.Name';

import APPROVER_GB_ID from "@salesforce/schema/DMT_Line__c.DMT_ApproverGlobalBanker__c";
import APPROVER_GB_NAME from '@salesforce/schema/DMT_Line__c.DMT_ApproverGlobalBanker__r.Name';


export default class Dmt_approval_process_data extends LightningElement {
    @api recordId; // Asumimos que este viene de la página de registro
    @track lineType;
    @track isEditing = false;
    @track isTreasury = true;
    @track isLoading = true;
    @track lineStatus;
    @track lineLock;
    @track isAllowedEditing = true;
    @track draftValues = {};
    @track draftLookupNames = {};
    @track wiredLineResult;
    @track bookingRiskId;
    @track bookingRiskName;
    @track approverId;
    @track approverName;
    @track approverGBId;
    @track approverGBName;
    currentUserId = USER_ID;

    get bookingRiskValueId() {
        return this.draftValues.DMT_Booking_Unit_Risk_Analyst__c ?? this.bookingRiskId;
    }
    get bookingRiskValueName() {
        return this.draftLookupNames.DMT_Booking_Unit_Risk_Analyst__c ?? this.bookingRiskName;
    }

    get approverValueId() {
        return this.draftValues.DMT_Approver__c ?? this.approverId;
    }

    get approverValueName() {
        return this.draftLookupNames.DMT_Approver__c ?? this.approverName;
    }

    get approverGBValueId() {
        return this.draftValues.DMT_ApproverGlobalBanker__c ?? this.approverGBId;
    }

    get approverGBValueName() {
        return this.draftLookupNames.DMT_ApproverGlobalBanker__c ?? this.approverGBName;
    }


    @wire(getRecord, {
        recordId: "$recordId",
        fields: [LINE_TYPE, LINE_STATUS, LINE_LOCK,
                BOOKING_RISK_ID, BOOKING_RISK_NAME,
                APPROVER_ID, APPROVER_NAME,
                APPROVER_GB_ID, APPROVER_GB_NAME]
    })
    wiredRecordLine(result) {
        this.wiredLineResult = result;
        this.isLoading = true;
        const {
            error,
            data
        } = result;
        if (error) {
            this.showToast('Error getting line info', error.body.message, 'error');
        } else if (data) {
            this.lineType = getFieldValue(data, LINE_TYPE);
            this.lineStatus = getFieldValue(data, LINE_STATUS);
            this.lineLock = getFieldValue(data, LINE_LOCK);
            this.bookingRiskId = getFieldValue(data, BOOKING_RISK_ID);
            this.bookingRiskName = getFieldValue(data, BOOKING_RISK_NAME);

            this.approverId = getFieldValue(data, APPROVER_ID);
            this.approverName = getFieldValue(data, APPROVER_NAME);

            this.approverGBId = getFieldValue(data, APPROVER_GB_ID);
            this.approverGBName = getFieldValue(data, APPROVER_GB_NAME);
            console.log('JACG estado ' + this.lineStatus);
            console.log('JACG lock ' + this.lineLock);

            const isDraft = this.lineStatus === 'Draft';
            const isNotLockedByOthers = (this.lineLock == null || this.lineLock === this.currentUserId);

            this.isAllowedEditing = isDraft && isNotLockedByOthers;
            this.isLoading = false;
        }
    }

    get approvalProcessDataColumns() {
        if (this.lineType == 'Treasury Line') {
            return [
                [{
                        fieldName: 'DMT_Booking_Unit_Risk_Analyst__c',
                        isReadOnly: false
                    },
                    {
                        fieldName: 'DMT_Approver__c',
                        isReadOnly: false
                    }
                ], // Columna 1
                [{
                        fieldName: 'DMT_GlobalBanker__c',
                        isReadOnly: true
                    },
                    {
                        fieldName: 'DMT_ApproverGlobalBanker__c',
                        isReadOnly: false
                    }
                ] // Columna 2
            ];
        } else {
            return [
                [{
                        fieldName: 'DMT_Booking_Unit_Risk_Analyst__c',
                        isReadOnly: false
                    },
                    {
                        fieldName: 'DMT_Approver__c',
                        isReadOnly: false
                    }
                ], // Columna 1
                [{
                        fieldName: 'DMT_GlobalBanker__c',
                        isReadOnly: true
                    },
                    {
                        fieldName: 'DMT_ApproverGlobalBanker__c',
                        isReadOnly: false
                    }
                ] // Columna 2
            ];
        }

    }

    get isLockedByOther() {
        return this.lineLock && this.lineLock != this.currentUserId;
    }

    get commentsColumns() {
        if (this.lineType == 'Treasury Line') {
            return [
                [{
                    fieldName: 'DMT_Client_Use__c',
                    isReadOnly: false
                }]
            ];
        } else {
            return [
                [{
                        fieldName: 'DMT_Comments__c',
                        isReadOnly: false
                    },
                    {
                        fieldName: 'DMT_Additional_Restrictions__c',
                        isReadOnly: false
                    }
                ]
            ];
        }

    }

    /*handleEditEvent(event) {
        const field = event.detail.field;
        console.log('JACG ' + field);
        const value = event.detail.value;
        const recordId = this.recordId;
        this.isEditing = true;console.log('isEditing', this.isEditing);
        getRecordNotifyChange([{recordId, fields: [field]}]);
        }*/

    async handleEditClick() {
        // Esta llamada VA al servidor sí o sí, el await esperará la respuesta real
        getLineLockStatus({ recordId: this.recordId }).then((result) => {
            console.log('JACG result ' + result);
            this.lineLock = result;
            if (this.lineLock == null || this.lineLock == this.currentUserId) {
            this.isEditing = true;
            this.dispatchEvent(new CustomEvent('editingtab', {
                bubbles: true,
                composed: true,
                detail: {
                    tab: 'approvalprocessdata'
                }
            }));
        }
        }) ;


    }

    // Método para refrescar los datos manualmente
    async handleRetry() {
        this.isLoading = true;
        try {
            // Esto fuerza a que el @wire(getRecord) se ejecute de nuevo
            await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            await refreshApex(this.wiredLineResult);
        } catch (error) {
            this.showToast('Error', 'No se pudo actualizar el estado de bloqueo', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleCancelClick(event) {
        this.isEditing = false;
        this.draftValues = {};
        this.draftLookupNames = {};
        // This event is used to tell the parent that you are not editing the tab anymore
        this.dispatchEvent(new CustomEvent('editingtab', {
            bubbles: true,
            composed: true,
            detail: {}
        }));
    }

    handleCustomFieldChange(event) {
        const fieldName = event.target.dataset.field;
        const { id, name } = event.detail;

        // Id (para updateRecord)
        this.draftValues = { ...this.draftValues, [fieldName]: id };

        // Name (para que el lookup mantenga la pill en pantalla durante edición)
        this.draftLookupNames = { ...this.draftLookupNames, [fieldName]: name };
    }

    handleCustomFieldClear(event) {
        const fieldName = event.target.dataset.field;
        this.draftValues[fieldName] = '';
        this.draftValues = { ...this.draftValues, [fieldName]: '' };
        this.draftLookupNames = { ...this.draftLookupNames, [fieldName]: '' };
    }

    handleStandardFieldChange(event) {
        const field = event.currentTarget?.fieldName; // <-- SIEMPRE aquí
        if (!field) {
            console.warn('handleStandardFieldChange: fieldName undefined', event);
            return;
        }

        const value = event.detail?.value ?? event.currentTarget?.value ?? event.target?.value;

        this.draftValues = { ...this.draftValues, [field]: value };
    }

    async handleSaveClick() {
        this.isLoading = true;
        // Solo procedemos si hay algo que actualizar
        if (Object.keys(this.draftValues).length === 0) {
            this.isEditing = false;
            this.isLoading = false;
            return;
        }

        const fields = {
            ...this.draftValues,
            Id: this.recordId
        };

        try {
            await updateRecord({
                fields
            });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Record updated successfully',
                    variant: 'success'
                })
            );
            this.isEditing = false;
            this.isLoading = false;
            this.draftValues = {};
            this.draftLookupNames = {};
            await getRecordNotifyChange([{
                recordId: this.recordId
            }]);
            this.dispatchEvent(new CustomEvent('editingtab', {
                bubbles: true,
                composed: true,
                detail: {}
            }));
        } catch (error) {
            console.log('JACG error ' + JSON.stringify(error))
            this.isLoading = false;
            if (error.body.output.hasOwnProperty('fieldErrors')) {
                console.log('JACG error entro aquí ' + JSON.stringify(Object.entries(error.body.output.fieldErrors)[0][1]))
                let message = '';
                for (let i = 0; i < Object.entries(error.body.output.fieldErrors).length; i++) {
                    message += Object.entries(error.body.output.fieldErrors)[i][0] + ': ' + Object.entries(error.body.output.fieldErrors)[i][1][0].message + '/';
                }

                this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error updating record',
                    message: message,
                    variant: 'error'
                })
            );
            } else {
                this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error updating record',
                    message: error.body.message,
                    variant: 'error'
                })
            );
            }
        }
    }
}