({
  setInitialValues: function (component) {
    component.set('v.mode', 'Input');
    component.set('v.objectApiName', 'Contact');
    component.set('v.iconName', 'standard:user');
    component.set('v.labelOwner', 'Contact Owner');
    component.set('v.labelAccount', 'Client Name');
    component.set('v.isWritable', true);

    const sObjectName = component.get('v.sObjectName');
    if (sObjectName === 'Contact') {
      component.set('v.title', 'Edit Contact: Desktop Contact');
    } else {
      component.set('v.title', 'New Contact: Desktop Contact');
    }

    this.handleInitValues(component);
  },
  handleInitValues: function (component) {
    let action = component.get('c.handleInitValues');
    action.setParams({
      'idAccount': component.get(' v.recordId ')
    });
    action.setCallback(this, function (response) {
      const resp = response.getReturnValue();

      if (response.getState() === 'SUCCESS') {
        if (resp.accId !== undefined && component.find('AccountId') !== undefined) {
          component.find('AccountId').set('v.value', resp.accId);
        }
        component.set('v.isSalesGM', resp.isGMProfile);

      } else {
        console.log(':::response.getState()' + JSON.stringify(response.getError()));
      }
    });
    $A.enqueueAction(action);
  },
  getDomain: function (component, event, helper) {
    let domain = component.get('c.currentDomain');
    domain.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        component.set('v.domain', response.getReturnValue());
      }
    });
    $A.enqueueAction(domain);
  },
  handleSubmit: function (component, event, mode, isConfirmed) {
    event.preventDefault();
    this.setMessageText(component, '', '', '', '', '', '', '', '', '', '');

    let eventFields = event.getParam('fields');
    if (eventFields) {
      component.set('v.eventFields', eventFields);
    } else {
      eventFields = component.get('v.eventFields');
    }
    let con = component.get('v.contact');

    let ownerRecord = component.get('v.selectedOwnerFiltered');


    let isChanged = false;
    if (mode === 'Update') {
      eventFields.Id = component.get('v.recordId');
      if (!isConfirmed) {
        isChanged = this.checkPrioritaryFields(component);
        if (isChanged) {
          component.set('v.showConfirmFields', true);
        }
      }
    }

    if (con) {
      eventFields.Email_ExternalID__c = con.Email_ExternalID__c;
      eventFields.firstName = con.FirstName;
      eventFields.lastName = con.LastName;
    } else {
      const email = component.get('v.email');
      eventFields.Email_ExternalID__c = email;
      const firstName = component.get('v.firstName');
      eventFields.firstName = firstName;
      const lastName = component.get('v.lastName');
      eventFields.lastName = lastName;
    }
    const phone = component.get('v.phone');
    eventFields.Phone = phone;
    eventFields.MobilePhone = component.get('v.mobilephone');

    eventFields.editable_field_type__c = true;
    const oldContact = component.get('v.ownerId');
    eventFields.OwnerId = ownerRecord == null ? null : ownerRecord.Id; //NOSONAR - Needed only double "="
    if (component.find('AccountId')) {
      eventFields.AccountId = component.find('AccountId').get('v.value');
    }
    let fieldsJSON = JSON.stringify(eventFields);

    if (!isChanged && isConfirmed) {
      this.createContact(component, fieldsJSON, mode, oldContact);
    } else if (!isChanged) {
      this.handleSubmit(component, event, 'Update', true);
    }
  },
  createContact: function (component, fieldsJSON, mode, oldContact) {
    let action = component.get('c.createContact');
    action.setParams({
      'attributes': fieldsJSON,
      'dmlOption': mode,
      'oldContact': oldContact
    });
    component.set('v.showSpinner', true);
    action.setCallback(this, function (response) {
      component.set('v.showSpinner', false);
      let state = response.getState();
      let resp = response.getReturnValue();

      if (state === 'SUCCESS' && resp.success === true) {
        let sObjectName = component.get('v.sObjectName');
        if (sObjectName === 'Contact') {
          window.location.reload();
        } else {
          this.navigateToContact(resp.rowId);
        }
      } else {
        if (resp === null) {
          this.setMessageText(component, 'error', 'Error', 'Errors, please contact with your admin', '', '');
        } else {
          if (resp.type === 'Duplicado') {
            this.setMessageText(component, 'error', 'Error', resp.bodyText, resp.rowId, resp.rowName, resp.accId, resp.accName, resp.ownId, resp.ownName, resp.ownDep);
          } else {
            this.setMessageText(component, 'error', 'Error', resp.bodyText, resp.rowId, resp.rowName);
          }
        }
      }
    });
    $A.enqueueAction(action);
  },
  getContactData: function (component, event, helper) {
    let action = component.get('c.getContactData');
    const idRecord = component.get('v.recordId');

    action.setParams({
      'idContact': idRecord
    });
    component.set('v.showSpinner', true);
    action.setCallback(this, function (response) {
      component.set('v.showSpinner', false);
      const state = response.getState();
      let resp = response.getReturnValue();

      if (state === 'SUCCESS') {
        component.set('v.contact', resp.contact);
        component.set('v.email', resp.contact.Email_ExternalID__c);
        component.set('v.lastName', resp.contact.LastName);
        component.set('v.firstName', resp.contact.FirstName);
        component.set('v.ownerId', resp.contact.OwnerId);
        component.set('v.phone', resp.contact.Phone);
        component.set('v.mobilephone', resp.contact.MobilePhone);

        if (component.get('v.sObjectName') === 'Contact') {
          component.set('v.isWritable', resp.canEdit);
        } else {
          component.set('v.isWritable', true);
        }
      } else {
        this.setMessageText(component, 'error', 'Error', 'Error recovering Contact´s Data', '', '');
      }
    });
    $A.enqueueAction(action);
  },
  checkPrioritaryFields: function (component) {
    let updatedContact = component.get('v.contact');
    let email = component.get('v.email');
    let firstName = component.get('v.firstName');
    let lastName = component.get('v.lastName');
    let isChanged;

    switch (false) {
      case updatedContact.FirstName === firstName:
        isChanged = true;
        break;
      case updatedContact.LastName === lastName:
        isChanged = true;
        break;
      case updatedContact.Email_ExternalID__c === email:
        isChanged = true;
        break;
      default:
        isChanged = false;
        break;
    }
    return isChanged;
  },
  setMessageText: function (component, severity, title, description, rowId, rowName, accId, accName, ownerId, ownerName, ownerDep) { //NOSONAR
    let messageObject = {
      'title': title,
      'body': description,
      'severity': severity,
      'rowId': rowId,
      'rowUrl': '/' + rowId,
      'rowName': rowName,
      'accUrl': '/' + accId,
      'accName': accName,
      'ownUrl': '/' + ownerId,
      'ownName': ownerName,
      'ownDep': ownerDep
    }
    component.set('v.message', messageObject);
  },
  toggleSpinner: function (component) {
    const spinner = component.find('spinnerLoading');
    $A.util.toggleClass(spinner, 'slds-hide');
  },
  navigateToContact: function (rowId) {
    let navEvt = $A.get('e.force:navigateToSObject');
    navEvt.setParams({
      'recordId': rowId,
      'slideDevName': 'detail'
    });
    navEvt.fire();
  },
  goBackFirstScreen: function (component, event, helper) {
    component.set('v.showConfirmFields', false);
  },
  closeModal: function (component, event, helper) {
    const isQuickAction = component.get('v.isQuickAction');
    if (isQuickAction) {
      $A.get('e.force:closeQuickAction').fire();
    } else {
      const nameDomain = component.get('v.domain');
      window.location.replace(nameDomain + '.lightning.force.com/one/one.app?source=aloha#/sObject/Contact/list?filterName=Recent');
    }
  },
})