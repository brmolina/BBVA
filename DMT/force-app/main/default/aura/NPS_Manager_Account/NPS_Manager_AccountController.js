({
  doInit: function(component, event, helper) {
    console.log('::::::::::recordId: ' + component.get('v.recordId'));
    var action = component.get('c.getNPSInformation');
    action.setParams({
      'iRecordId': component.get('v.recordId')
    })
    action.setCallback(this, function(response) {
      var state = response.getState();
      if(state === "SUCCESS") {
        component.set('v.account', response.getReturnValue());
        component.set('v.initialValue', component.get('v.account').survey_nps_contact_type__c);
        console.log('::::::::::account: ' + component.get('v.account'));
        console.log('::::::::::account.survey_nps_contact_type__c: ' + component.get('v.account').survey_nps_contact_type__c);
      }
    });
    $A.enqueueAction(action);
  },

  openModal: function(component, event, helper) {
    component.set("v.isModalOpen", true);
  },

  closeModal: function(component, event, helper) {
    if(component.get('v.initialValue') !== component.get('v.account').survey_nps_contact_type__c) {
      var action = component.get('c.updateNPSInformation');
      action.setParams({
        'iRecordId': component.get('v.recordId'),
        'iNPS': component.get('v.account').survey_nps_contact_type__c
      })
      action.setCallback(this, function(response) {
        var state = response.getState();
        if(state === "SUCCESS") {

          component.set("v.isModalOpen", false);
          var toastEvent = $A.get("e.force:showToast");
          toastEvent.setParams({
            title : 'Success',
            message: 'The record has been saved successfully.',
            duration:'5000',
            type: 'success',
            mode: 'pester'
          });
          toastEvent.fire();
          $A.get('e.force:refreshView').fire();
        } else if(state === "ERROR") {
          var errorMessage = JSON.stringify(response.getError()).substring(
            JSON.stringify(response.getError()).lastIndexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION, ') + ('FIELD_CUSTOM_VALIDATION_EXCEPTION, ').length,
            JSON.stringify(response.getError()).lastIndexOf(':')
          );
          component.set("v.isModalOpen", false);
          component.set("v.isOpen", false);
          var toastEventError = $A.get("e.force:showToast");
          toastEventError.setParams({
            title : 'Error',
            message: errorMessage,
            duration:'10000',
            type: 'error',
            mode: 'pester'
          });
          toastEventError.fire();
          $A.get('e.force:refreshView').fire();
        }
      });
      $A.enqueueAction(action);
    } else {
      component.set("v.isModalOpen", false);
      var toastEvent = $A.get("e.force:showToast");
      toastEvent.setParams({
        title : 'Success',
        message: 'The record has been saved successfully.',
        duration:'5000',
        type: 'success',
        mode: 'pester'
      });
      toastEvent.fire();
      $A.get('e.force:refreshView').fire();
    }
  },
})