({
  init: function(component, event, helper) {
    component.set('v.isModalOpen', true);
    component.set('v.isOpen', true);
    component.set("v.recordId", component.get("v.inputAttributes").recordId);

    helper.gtOpportunity(component);
    helper.getStatusOfAction(component, component.get("v.status_of_action"));
    helper.getReasonsLost(component, component.get("v.reasons_lost"));
  },

  closeModal: function(component, event, helper) {
    component.set("v.isModalOpen", false);
    component.set("v.isOpen", false);
    component.set("v.isOpen2", false);
  },

  continue: function(component, event, helper) {
    component.set("v.isOpen", false);
    component.set("v.isOpen2", true);

  },

  save_enable: function(component, event, helper) {
    if(component.find("confirm_opportunity").get("v.checked") === true) {
      component.set("v.save_disabled", false);
    } else {
      component.set("v.save_disabled", true);
    }
  },

  closeModalOnFinish: function(component, event, helper) {
    var action = component.get("c.updateClosedLostOpportunity");
    action.setParams({
      'iRecordId': component.get('v.inputAttributes').recordId,
      'iReason': component.get('v.reasons_lost_value'),
      'iDescription': component.get('v.description_value')
    })
    action.setCallback(this, function(response) {
      var state = response.getState();
      if(state === "SUCCESS") {
        component.set("v.isModalOpen", false);
        component.set("v.isOpen", false);
        component.set("v.isOpen2", false);
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
        component.set("v.isOpen2", false);
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
  }
})