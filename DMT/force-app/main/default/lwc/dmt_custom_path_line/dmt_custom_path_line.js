import { LightningElement, wire, api, track } from 'lwc'
import { getObjectInfo } from 'lightning/uiObjectInfoApi'
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { getPicklistValues } from 'lightning/uiObjectInfoApi'
import { getRecord, updateRecord } from 'lightning/uiRecordApi'
import DMT_LINE_OBJECT from '@salesforce/schema/DMT_Line__c'
import STATUS_FIELD from '@salesforce/schema/DMT_Line__c.Status__c'
import CLIENT_TYPE_FIELD from '@salesforce/schema/DMT_Line__c.Client_Type__c'
import CLIENT_ID_FIELD from '@salesforce/schema/DMT_Line__c.Client__c'
import RECORD_TYPE_FIELD from '@salesforce/schema/DMT_Line__c.RecordTypeId'
import ID_FIELD from '@salesforce/schema/DMT_Line__c.Id'
import WON_LOST_FIELD from '@salesforce/schema/DMT_Line__c.Closed__c'
import GEOGRAPHY_FIELD from '@salesforce/schema/DMT_Line__c.Booking_Geography__c'
import DATETOPROPOSAL_FIELD from '@salesforce/schema/DMT_Line__c.DMT_DateToProposal__c'
import LINE_TEMPLATE from '@salesforce/schema/DMT_Line__c.DMT_line_template_type__c'
import DMT_Not_Approval_Required_Permission from '@salesforce/customPermission/DMT_Not_Approval_Required'
import compareTaskFromCaseLWC from '@salesforce/apex/DMT_ApprovalChangeStep_Handler.compareTasksFromCaseLWC'
import getRelatedTRSRLinesByLineId from '@salesforce/apex/DMT_View_Selector.getRelatedTRSRLinesByLineId'
import getCustomAssociationClientByLineId from '@salesforce/apex/DMT_View_Selector.getCustomAssociationClientByLineId'
import previewCompareTasksFromCase from '@salesforce/apex/DMT_ApprovalChangeStep_Handler.previewCompareTasksFromCase'
import fetchClientDataFromServiceLine from '@salesforce/apex/DMT_HPG_MainTableCustomController.fetchClientDataFromServiceLine';
import lastDate from '@salesforce/apex/DMT_HPG_Utils.lastDate';

const ERROR_INVALID_UPDATING = 'Error updating status:'
const ERROR_TITLE =
  'You encountered some errors when trying to save this record'
const ERROR_GETTING_VALUES = 'Error getting values ​​from picklist:'
const ERROR_PERMISSION =
  'Unable to create/update fields: Status. Please check the security settings of this field and verify that it is read/write for your profile or permission set.'
const SUCCESS_UPDATING = 'Status changed successfully.'
const NOT_APPROVAL_REQUIRED_MESSAGE = 'The application status will be advanced without completion of the approval process within Deal Management Tool (Global Desktop). Do you wish to proceed?';
const STAGES_DISABLED_FOR_APPROVAL = ['Draft', 'Proposal'];
const STAGE_APPROVAL = 'Approval';
export default class Dmt_custom_path_line extends LightningElement {
  @api recordId
  status
  clientType
  clientId
  selectedStage
  geography
  wonLostValue
  dateToProposal
  lineTemplate
  @wire(getObjectInfo, { objectApiName: DMT_LINE_OBJECT })
  objectInfo
  wonLostOptions = []
  stages
  showModal = false
  _rawStages
  showNotApprovalModal = false;
  draftProposalMessage = '';
  showTreasuryToExpire = false;
  showTreasuryToExpireMessage;
  isReadOnly = false;
  stagesToDisable = [];

  get message_not_approval_required_aux() {
    return NOT_APPROVAL_REQUIRED_MESSAGE;
  }

  get hasNotApprovalPermission() {
    return DMT_Not_Approval_Required_Permission;
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
      CLIENT_TYPE_FIELD,
      CLIENT_ID_FIELD,
      GEOGRAPHY_FIELD,
      WON_LOST_FIELD,
      DATETOPROPOSAL_FIELD,
      LINE_TEMPLATE
    ]
  })
  record ({ error, data }) {
    if (data) {
      this.status = data.fields.Status__c.value
      this.clientType = data.fields.Client_Type__c.value
      this.clientId = data.fields.Client__c.value
      this.geography = data.fields.Booking_Geography__c.value
      this.wonLostValue = data.fields.Closed__c.value
      this.dateToProposal = data.fields.DMT_DateToProposal__c.value
      this.lineTemplate = data.fields.DMT_line_template_type__c.value
      this.selectedStage = this.status
      this.stagesToDisable = data.recordTypeInfo.name == STAGE_APPROVAL ? STAGES_DISABLED_FOR_APPROVAL : [];
      this.isReadOnly = data.recordTypeInfo.name == STAGE_APPROVAL;

      if(this.status && this.status == 'Ready to close' && this.geography !== 'PE' && this.lineTemplate != 'OP') {
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
    this.selectedStage = event.detail.selectedStage;

    if(this.selectedStage &&
      (this.selectedStage.includes('Closed')  ||
      this.selectedStage.includes('Ready to close')) &&
      (this.status == 'Draft' || this.status == 'Proposal' || this.status == 'Approval') &&
      this.hasNotApprovalPermission == true ) {

        this.showNotApprovalModal = true
    }

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
    console.log('nextStage: '+nextStage);
    const childComponent = this.template.querySelector('.childCustomPath')
    if((nextStage == 'Closed'  ||
      nextStage == 'Ready to close') &&
      (this.status == 'Draft' || this.status == 'Proposal' || this.status == 'Approval') &&
      this.hasNotApprovalPermission == true ) {
        this.selectedStage = nextStage;
        this.showNotApprovalModal = true
        childComponent.setLoading(false)
        childComponent.setIsDisabled(false)
        return;
    }
    if (nextStage && nextStage.includes('Closed') && this.geography === 'PE') {
      this.showModal = true
      if (childComponent) {
        childComponent.setLoading(false)
        childComponent.setIsDisabled(false)
      }
      return
    }

    if (this.status == 'Draft' && nextStage != 'Draft' && this.dateToProposal) {
      compareTaskFromCaseLWC({ lineId: this.recordId});
      previewCompareTasksFromCase({ lineId: this.recordId}).then(result => {
        console.log('result JACG: '+JSON.stringify(result));
        if (result && result.length === 0) {
          this.draftProposalMessage = 'There is no task or case created, so the draft-proposal logic won\'t be operating';
        }
        else if (result && result.length === 1 && !result[0].hasOwnProperty("changedFields")) {
          this.draftProposalMessage = 'There has been no changes in the line, so the last feature will continue to be open: ' + result[0].featureName;
        } else {
          for (let i = 0; i < result.length; i++) {
            const ownerName =
              result[i] &&
              result[i].taskToRecreate &&
              result[i].taskToRecreate.Owner &&
              result[i].taskToRecreate.Owner.Name
                ? result[i].taskToRecreate.Owner.Name
                : 'N/A'
            this.draftProposalMessage += 'The feature  ' + result[i].featureName + ' has been reopened with Owner: <b>' + ownerName + '</b> due to changes in the following fields: <ul class="slds-list_dotted">';
            for (let key in result[i].changedFields) {
              this.draftProposalMessage += '<li>' + key + '</li>'
            }
            //this.draftProposalMessage = this.draftProposalMessage.slice(0, -2);
            this.draftProposalMessage += '</ul><br/>'
          }

           /*this.dispatchEvent(
          new ShowToastEvent({
            title: 'Reopened Features',
            message: this.draftProposalMessage,
            variant: 'info',
            mode: 'sticky'
          }));*/
          const toastComponent = this.template.querySelector('c-dmt_customtoast');
          if (toastComponent) {
              toastComponent.showToast('Reopened Features', this.draftProposalMessage, 'info', false);
          } else {
              console.error('No se encontró el componente dmt_customtoast en el DOM');
          }
        }
      })

    }

    if (this.status == 'Draft' && nextStage != 'Draft' && this.lineTemplate == 'TL') {
      getRelatedTRSRLinesByLineId({ recordId: this.recordId })
        .then((relatedLines) => {
            if (relatedLines && relatedLines.length > 0) {
                const relatedLinesBulletList = relatedLines
                  .map(line => {
                    const lineName = line.Name || 'Unnamed line'
                    const lineId = line.Line_Id__c || 'N/A'
                    return '- ' + lineName + ' (' + lineId + ')'
                  })
                  .join('\n')
                this.showTreasuryToExpireMessage =
                    'In case of approval of this line, the following previous lines will be cancelled (changing maturity date to avoid overlapping with the new line):\n\n' +
                    relatedLinesBulletList;

              const openTreasuryModal = () => {
                this.selectedStage = nextStage;
                this.showTreasuryToExpire = true;
                childComponent.setLoading(false)
                childComponent.setIsDisabled(false)
              }

              const handleGlobalPositionResult = (globalPositionResult, allowedCustomerIds) => {
                const rows = globalPositionResult && globalPositionResult.data ? globalPositionResult.data : [];

                let filteredRows = rows.filter(row => !row.customerCounterpartiesCodesDesc);

                if (allowedCustomerIds && allowedCustomerIds.length > 0 && this.clientType === 'Custom') {
                  filteredRows = filteredRows.filter(row => allowedCustomerIds.includes(row.customerId))
                }

                if (filteredRows.length > 0) {
                  this.showTreasuryToExpireMessage += '\n\nAdditionally, these clients have no counterparty code to trade Global Markets products:\n\n' + filteredRows.map(row => row.customerId).join(', ')+'.';
                }

              }

              if (this.clientType === 'Customer' && this.clientId) {
                lastDate()
                  .then((searchDate) => fetchClientDataFromServiceLine({
                    clientId: this.clientId,
                    page: '1',
                    pageSize: '5000',
                    countries: [],
                    searchDate,
                    clientPositionsType: 'Y',
                    customerId: null
                  }))
                  .then((globalPositionResult) => {
                    handleGlobalPositionResult(globalPositionResult)
                  })
                  .catch((error) => {
                    console.error('Error retrieving global position data (Customer)', error)
                  })
                  .finally(() => {
                    openTreasuryModal()
                  })
                return;
              } else if (this.clientType === 'Custom' && this.clientId) {
                let _searchDate
                let _allowedCustomerIds
                lastDate()
                  .then((searchDate) => {
                    _searchDate = searchDate
                    return getCustomAssociationClientByLineId({ lineId: this.recordId })
                  })
                  .then((associationClients) => {
                    _allowedCustomerIds = (associationClients || []).map(ac => ac.g_customer_id__c).filter(Boolean)
                    return fetchClientDataFromServiceLine({
                      clientId: this.clientId,
                      page: '1',
                      pageSize: '5000',
                      countries: [],
                      searchDate: _searchDate,
                      clientPositionsType: 'Y',
                      customerId: null
                    })
                  })
                  .then((globalPositionResult) => {
                    handleGlobalPositionResult(globalPositionResult, _allowedCustomerIds)
                  })
                  .catch((error) => {
                    console.error('Error retrieving global position data (Custom)', error)
                  })
                  .finally(() => {
                    openTreasuryModal()
                  })
                return;
              }

              openTreasuryModal()
              return;
            } else {
              this.updateStatus(nextStage)
            }
        })
        .catch((error) => {
            console.error('Error retrieving related lines', error);
        });
    } else {
    this.updateStatus(nextStage)
  }
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
    const childComponent = this.template.querySelector('.childCustomPath')
    childComponent.setLoading(true)
    childComponent.setIsDisabled(true)
    this.updateStatus(this.selectedStage);
    this.showNotApprovalModal = false;
    this.showTreasuryToExpire = false;
  }

  cancelModalNotApproval () {
    this.selectedStage = this.status;
    this.showNotApprovalModal = false;
    this.showTreasuryToExpire = false;
  }
}