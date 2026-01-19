import { LightningElement, wire, api, track } from 'lwc'
import { getObjectInfo } from 'lightning/uiObjectInfoApi'
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { getPicklistValues } from 'lightning/uiObjectInfoApi'
import { getRecord, updateRecord } from 'lightning/uiRecordApi'
import DMT_LINE_OBJECT from '@salesforce/schema/DMT_Line__c'
import STATUS_FIELD from '@salesforce/schema/DMT_Line__c.Status__c'
import ID_FIELD from '@salesforce/schema/DMT_Line__c.Id'
import WON_LOST_FIELD from '@salesforce/schema/DMT_Line__c.Closed__c'
import GEOGRAPHY_FIELD from '@salesforce/schema/DMT_Line__c.Booking_Geography__c'
import DATETOPROPOSAL_FIELD from '@salesforce/schema/DMT_Line__c.DMT_DateToProposal__c'
import DMT_Not_Approval_Required_Permission from '@salesforce/customPermission/DMT_Not_Approval_Required'

import previewCompareTasksFromCase from '@salesforce/apex/DMT_ApprovalChangeStep_Handler.previewCompareTasksFromCase'
import { CurrentPageReference } from 'lightning/navigation';
const ERROR_INVALID_UPDATING = 'Error updating status:'
const ERROR_TITLE =
  'You encountered some errors when trying to save this record'
const ERROR_GETTING_VALUES = 'Error getting values ​​from picklist:'
const ERROR_PERMISSION =
  'Unable to create/update fields: Status. Please check the security settings of this field and verify that it is read/write for your profile or permission set.'
const SUCCESS_UPDATING = 'Status changed successfully.'
const NOT_APPROVAL_REQUIRED_MESSAGE = 'The application status will be advanced without completion of the approval process within Deal Management Tool (Global Desktop). Are you sure you wish to proceed?';

export default class Dmt_custom_path_line extends LightningElement {
  @api recordId
  status
  selectedStage
  geography
  wonLostValue
  dateToProposal
  @wire(getObjectInfo, { objectApiName: DMT_LINE_OBJECT })
  objectInfo
  wonLostOptions = []
  stages
  showModal = false
  _rawStages
  showNotApprovalModal = false;

  get message_not_approval_required_aux() {
    return NOT_APPROVAL_REQUIRED_MESSAGE;
  }

  get hasNotApprovalPermission() {
    return DMT_Not_Approval_Required_Permission;
  }


      @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {            
            // Check standard and custom state parameters
            this.recordId = currentPageReference.state?.recordId || currentPageReference.state?.c__recordId || currentPageReference.attributes?.recordId;
        }
    }

  @wire(getPicklistValues, {
    recordTypeId: '$objectInfo.data.defaultRecordTypeId',
    fieldApiName: STATUS_FIELD
  })
  picklistValues ({ error, data }) {
    if (data) {
      this._rawStages = data.values.map(option => option.value)
      this.calculateStages();
    } else if (error) {
      console.error(ERROR_GETTING_VALUES, error)
    }
  }

  @wire(getPicklistValues, {
    recordTypeId: '$objectInfo.data.defaultRecordTypeId',
    fieldApiName: WON_LOST_FIELD
  })
  wiredWonLost ({ error, data }) {
    if (data) {
      this.wonLostOptions = data.values.map(option => ({
        label: option.label,
        value: option.value
      }))
    } else if (error) {
      console.error(ERROR_GETTING_VALUES, error)
    }
  }

  @wire(getRecord, {
    recordId: '$recordId',
    fields: [
      STATUS_FIELD,
      GEOGRAPHY_FIELD,
      WON_LOST_FIELD,
      DATETOPROPOSAL_FIELD
    ]
  })
  record ({ error, data }) {
    if (data) {
      this.status = data.fields.Status__c.value
      this.geography = data.fields.Booking_Geography__c.value
      this.wonLostValue = data.fields.Closed__c.value
      this.dateToProposal = data.fields.DMT_DateToProposal__c.value
      this.selectedStage = this.status

      if(this.status && this.status == 'Ready to close' && this.geography !== 'PE') {
        this.status = 'Closed'
        this.wonLostValue = 'Won'
        this.selectedStage = this.status
      }

      this.calculateStages();
    } else if (error) {
      console.error(error)
    }
  }

  handleStageClick (event) {
    this.selectedStage = event.detail.selectedStage
    console.log('this.selectedStage: '+this.selectedStage);
    console.log('this.this.status: '+this.status);
    const childComponent = this.template.querySelector('.childCustomPath')
    if (this.selectedStage && !this.selectedStage.includes('Closed')) {
      if (childComponent) {
          childComponent.setIsDisabled(false)
      }
    } else if (this.selectedStage && this.selectedStage.includes('Closed') && this.status && this.status.includes('Closed')) {
       if (childComponent) {
          childComponent.setIsDisabled(true)
      }
    }

    if (this.selectedStage &&
      this.selectedStage.includes('Closed') &&
      this.geography === 'PE' &&
      this.status &&
      !this.status.includes('Closed')
    ) {
      this.showModal = true
     } else {
      this.showModal = false
    }

     
    if(this.selectedStage &&
      (this.selectedStage.includes('Closed')  ||
      this.selectedStage.includes('Ready to close')) &&
      (this.status == 'Draft' || this.status == 'Proposal' || this.status == 'Approval') &&
      this.hasNotApprovalPermission == true ) {

        this.showNotApprovalModal = true
    }

     //else if (this.selectedStage &&
    //   this.selectedStage == 'Ready to close' &&
    //   this.geography !== 'PE')
    // {
    //   this.showModal = false
    //   this.status = 'Closed'
    // } 
   
  }

  calculateStages() {
    if (!this._rawStages) return;

    this.stages = this._rawStages.map(option => {
      if (option === 'Closed') {
        if (this.wonLostValue === 'Won') return 'Closed Won';
        if (this.wonLostValue === 'Lost') return 'Closed Lost';
      }
      return option;
    });

    if (this.status === 'Closed' && this.wonLostValue == 'Won') {
        this.selectedStage ='Closed Won'
        this.status = 'Closed Won'
      } else if (this.status === 'Closed' && this.wonLostValue == 'Lost') {
        this.selectedStage ='Closed Lost'
        this.status = 'Closed Lost'
      } else {
        this.selectedStage = this.status
      }
    if (
      (this.status && this.status.includes('Closed') && !this.selectedStage) ||
      (this.status && this.status.includes('Closed') && this.selectedStage && this.selectedStage.includes('Closed'))) {
        const childComponent = this.template.querySelector('.childCustomPath')
        console.log('JACG Entro aqui ' + childComponent);
        if (childComponent) {
          childComponent.setIsDisabled(true)
        }
      }
  }

  handleMarkComplete (event) {
    let nextStage = event.detail.nextStage
    const childComponent = this.template.querySelector('.childCustomPath')

    if (nextStage && nextStage.includes('Closed') && this.geography === 'PE') {
      this.showModal = true
      if (childComponent) {
        childComponent.setLoading(false)
        childComponent.setIsDisabled(false)
      }
      return
    }
    this.updateStatus(nextStage)
  }

  updateStatus (newStatus) {
    const fields = {}
    fields[ID_FIELD.fieldApiName] = this.recordId
    fields[STATUS_FIELD.fieldApiName] = newStatus
    fields[WON_LOST_FIELD.fieldApiName] = this.wonLostValue

    const recordInput = { fields }
    const childComponent = this.template.querySelector('.childCustomPath')

    updateRecord(recordInput)
      .then(() => {
        this.status = newStatus
        if (childComponent) {
          childComponent.setLoading(false)
          childComponent.setIsDisabled(true)
        }
        this.selectedStage = newStatus
        this.dispatchEvent(
          new ShowToastEvent({
            title: '',
            message: SUCCESS_UPDATING,
            variant: 'success'
          })
        )
      })
      .catch(error => {
        if (childComponent) {
          childComponent.setLoading(false)
          childComponent.setIsDisabled(false)
        }

        const errorStatus = error.status
        const errorMessage =
          errorStatus === 403
            ? ERROR_PERMISSION
            : error.body.output.errors[0].message

        this.dispatchEvent(
          new ShowToastEvent({
            title: ERROR_TITLE,
            message: errorMessage,
            variant: 'error'
          })
        )
        console.error(ERROR_INVALID_UPDATING, error)
      })
      .finally(() => {
        if (childComponent) {
          childComponent.setLoading(false)
          childComponent.setIsDisabled(false)
        }
      })
  }

  handleWonLostChange (event) {
    this.wonLostValue = event.target.value
  }

  handleModalSave () {
    const fields = {}
    fields[ID_FIELD.fieldApiName] = this.recordId
    fields[STATUS_FIELD.fieldApiName] = 'Ready to close'
    fields[WON_LOST_FIELD.fieldApiName] = this.wonLostValue

    const recordInput = { fields }

    updateRecord(recordInput)
      .then(() => {
        this.status = 'Ready to close'
        this.selectedStage = 'Ready to close'
        this.showModal = false
      })
      .catch(error => {
        console.error(ERROR_INVALID_UPDATING, error)
      })
  }

  saveModal () {
    const childComponent = this.template.querySelector('.childCustomPath')
    if (childComponent) {
      childComponent.setLoading(true)
      childComponent.setIsDisabled(true)
    }
    this.showModal = false

    const fields = {}
    fields[ID_FIELD.fieldApiName] = this.recordId
    fields[WON_LOST_FIELD.fieldApiName] = this.wonLostValue
    fields[STATUS_FIELD.fieldApiName] = 'Closed'

    const recordInput = { fields }

    updateRecord(recordInput)
      .then(() => {
        this.status = 'Closed'
        this.selectedStage = 'Closed'
        this.isDisabled = true;
        this.isClosed = true;
        if (childComponent) {
          childComponent.setIsDisabled(true)
        }
        this.dispatchEvent(
          new ShowToastEvent({
            title: '',
            message: SUCCESS_UPDATING,
            variant: 'success'
          })
        )
      })
      .catch(error => {
        const errorStatus = error.status
        const errorMessage =
          errorStatus === 403
            ? ERROR_PERMISSION
            : error.body.output.errors[0].message

        this.wonLostValue = ''

        this.dispatchEvent(
          new ShowToastEvent({
            title: ERROR_TITLE,
            message: errorMessage,
            variant: 'error'
          })
        )
        console.error(ERROR_INVALID_UPDATING, error)
      })

      .finally(() => {
        if (childComponent) {
          childComponent.setLoading(false)
          childComponent.setIsDisabled(false)
        }
      })
  }

  closeModal () {
    this.showModal = false
  }

  closeModalNotApproval () {
    this.showNotApprovalModal = false;
  }
}