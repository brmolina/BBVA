import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord, updateRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import RECORDID_FIELD from '@salesforce/schema/Opportunity.Id';
import RECORDTYPEID_FIELD from '@salesforce/schema/Opportunity.RecordTypeId';
import STAGENAME_FIELD from '@salesforce/schema/Opportunity.StageName';
import REASONLOST_FIELD from '@salesforce/schema/Opportunity.DES_Reasons_Lost__c';
import DESCRIPTION_REASON_FIELD from '@salesforce/schema/Opportunity.DES_Description_reason_for_lost_deal__c';

export default class DmtCloseOppModal extends LightningElement {
  @api recordId;
  comment = '';
  selectedCategory = '';
  @api categoryOptions = [];
  _recordTypeId;
  isLoading = false;

  get submitButtonLabel() {
    return this.isLoading ? 'Closing...' : 'Close Opportunity';
  }

  @wire(getRecord, {
    recordId: '$recordId',
    fields: [RECORDTYPEID_FIELD]
  })
  record({ data }) {
    if (data) {
      this._recordTypeId = data.fields.RecordTypeId.value;
    }
  }

  handleCategoryChange(event) {
    this.selectedCategory = event.detail.value;
  }

  handleCommentChange(event) {
    this.comment = event.detail.value;
  }

  @wire(getPicklistValues, {
    recordTypeId: '$_recordTypeId',
    fieldApiName: REASONLOST_FIELD
  })
  picklistValuesReasonLost({ data }) {
    if (data) {
      this.categoryOptions = data.values.map((option) => ({
        label: option.label,
        value: option.value
      }));
    }
  }

  handleCloseOpportunity() {
    // Validate required fields
    if (!this.selectedCategory) {
      this.showToast('Error', 'Please select a lost reason for the opportunity', 'error');
      return;
    }

    if (!this.comment || this.comment.trim() === '') {
      this.showToast('Error', 'Please enter a close comment', 'error');
      return;
    }

    this.isLoading = true;

    // Actualizar el registro de Oportunidad
    const fields = {
      [RECORDID_FIELD.fieldApiName]: this.recordId,
      [STAGENAME_FIELD.fieldApiName]: 'Closed Lost',
      [REASONLOST_FIELD.fieldApiName]: this.selectedCategory,
      [DESCRIPTION_REASON_FIELD.fieldApiName]: this.comment
    };

    updateRecord({ fields })
      .then(() => {
        notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
        this.showToast('Success', 'Opportunity closed successfully', 'success');
        this.resetForm();
        // Cerrar la modal después de 1.5 segundos
        setTimeout(() => {
          this.isLoading = false;
          this.dispatchEvent(new CloseActionScreenEvent());
        }, 1500);
      })
      .catch(error => {
        this.isLoading = false;
        const errorMessage = error?.body?.message || error?.message || 'Error updating the record';
        this.showToast('Error', errorMessage, 'error');
      });
  }

  resetForm() {
    this.comment = '';
    this.selectedCategory = '';
  }

  showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(event);
  }
}