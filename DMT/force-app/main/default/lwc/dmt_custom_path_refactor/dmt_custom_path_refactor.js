import { LightningElement, wire, api, track } from 'lwc'
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { getObjectInfo } from 'lightning/uiObjectInfoApi'
import { getPicklistValues } from 'lightning/uiObjectInfoApi'
import { getRecord, updateRecord } from 'lightning/uiRecordApi'
import { loadStyle } from 'lightning/platformResourceLoader'

import DMT_Styles from '@salesforce/resourceUrl/DMT_Styles'
import DMT_LINE_OBJECT from '@salesforce/schema/DMT_Line__c'
import STATUS_FIELD from '@salesforce/schema/DMT_Line__c.Status__c'
import ID_FIELD from '@salesforce/schema/DMT_Line__c.Id'
import WON_LOST_FIELD from '@salesforce/schema/DMT_Line__c.Closed__c'
import GEOGRAPHY_FIELD from '@salesforce/schema/DMT_Line__c.Booking_Geography__c'
import DATETOPROPOSAL_FIELD from '@salesforce/schema/DMT_Line__c.DMT_DateToProposal__c'
import previewCompareTasksFromCase from '@salesforce/apex/DMT_ApprovalChangeStep_Handler.previewCompareTasksFromCase'

const EVENT_SET = 'Set'
const ERROR_INVALID_STYLE = 'Error loading static resource styles.'
const ERROR_INVALID_UPDATING = 'Error updating status:'
const ERROR_TITLE =
  'You encountered some errors when trying to save this record'
const ERROR_STATIC_RESOURCE = 'Error loading static resource styles:'
const ERROR_GETTING_VALUES = 'Error getting values ​​from picklist:'
const ERROR_PERMISSION =
  'Unable to create/update fields: Status. Please check the security settings of this field and verify that it is read/write for your profile or permission set.'
const SUCCESS_UPDATING = 'Status changed successfully.'

export default class dmt_custom_path extends LightningElement {
  @api recordId
  status
  stages = []
  showModal = false
  selectedStage
  wonLostOptions = []
  isLoading = false
  dateToProposal

  get isClosed () {
    return (
      (this.status === 'Closed' && this.selectedStage == null) ||
      (this.status === 'Closed' && this.selectedStage == 'Closed')
    )
  }

  get buttonLabel () {
    if (this.isLoading) {
      return 'Saving...'
    }

    if (this.selectedStage && this.selectedStage !== this.status) {
      return 'Mark as Current Status'
    }
    return 'Mark Status as Complete'
  }

  get isDisabled () {
    return this.isLoading || this.isClosed
  }

  get buttonIcon () {
    return this.isLoading ||
      (this.selectedStage && this.selectedStage !== this.status)
      ? null
      : 'utility:check'
  }

  renderedCallback () {
    Promise.all([loadStyle(this, DMT_Styles)])
      .then(() => {
        console.log('Static Resource Loaded')
      })
      .catch(error => {
        console.log('error-', error)
      })
  }

  @wire(getObjectInfo, { objectApiName: DMT_LINE_OBJECT })
  objectInfo

  @wire(getPicklistValues, {
    recordTypeId: '$objectInfo.data.defaultRecordTypeId',
    fieldApiName: STATUS_FIELD
  })
  picklistValues ({ error, data }) {
    if (data) {
      this.stages = data.values.map(option => option.value)
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
      this.selectedStage = this.status
      this.geography = data.fields.Booking_Geography__c.value
      this.wonLostValue = data.fields.Closed__c.value
      this.dateToProposal = data.fields.DMT_DateToProposal__c.value
    } else if (error) {
      console.error(error)
    }
  }

  handleStageClick (event) {
    this.selectedStage = event.detail.stage || event.target.value

    if (
      this.selectedStage === 'Closed' &&
      this.geography === 'PE' &&
      this.status != 'Closed'
    ) {
      this.showModal = true
    } else {
      this.showModal = false
    }
  }

  handleMarkComplete () {
    this.isLoading = true

    let nextStage

    if (this.selectedStage && this.selectedStage !== this.status) {
      nextStage = this.selectedStage
    } else {
      const currentIndex = this.stages.indexOf(this.status)
      const nextIndex = currentIndex + 1

      if (nextIndex >= this.stages.length) {
        this.isLoading = false
        return
      }

      nextStage = this.stages[nextIndex]
    }

    if (nextStage === 'Closed' && this.geography === 'PE') {
      this.showModal = true
      this.isLoading = false
      return
    } else if (nextStage === 'Proposal' && this.dateToProposal) {
      previewCompareTasksFromCase({ recordId: this.recordId }).then(result => {
        this.isLoading = false
        if (result.length == 0) {
          this.dispatchEvent(
            new ShowToastEvent({
              title: 'Returned to Proposal',
              message: 'No tasks exist, so none will be reopened.',
              variant: 'success',
              mode: 'sticky'
            })
          )
        }
      })
    }
    this.updateStatus(nextStage)
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
    this.isLoading = true
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
        this.isDisabled = true
        this.isClosed = true
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
        this.isLoading = false
      })
  }

  closeModal () {
    this.showModal = false
  }

  loadComponentStyles () {
    if (this._stylesLoaded) {
      return
    }
    loadStyle(this, DMT_Styles)
      .then(() => {
        this._stylesLoaded = true
      })
      .catch(error => {
        pubsub.fire(EVENT_SET, 'Error', { errorMessage: ERROR_INVALID_STYLE })
        console.error(ERROR_STATIC_RESOURCE, error)
      })
  }

  updateStatus (newStatus) {
    const fields = {}
    fields[ID_FIELD.fieldApiName] = this.recordId
    fields[STATUS_FIELD.fieldApiName] = newStatus
    fields[WON_LOST_FIELD.fieldApiName] = this.wonLostValue

    const recordInput = { fields }

    updateRecord(recordInput)
      .then(() => {
        this.status = newStatus
        this.isLoading = false
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
        this.isLoading = false

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
        this.isLoading = false
      })
  }
}