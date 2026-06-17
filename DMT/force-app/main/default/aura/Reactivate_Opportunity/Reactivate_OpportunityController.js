({
  init: function(component, event, helper) {
    component.set('v.isModalOpen', true);
    component.set('v.isOpen', true);
    component.set("v.recordId", component.get("v.inputAttributes").recordId);

    var today = new Date();
    var todaySum = new Date();
    todaySum.setDate(today.getDate() + 50);
    var todaySumString = todaySum.getFullYear() + "-" + (todaySum.getMonth() + 1) + "-" + todaySum.getDate();
    console.log('::::::::::todaySumString: ' + todaySumString);
    component.set("v.estimated_closing_date", todaySumString);
    component.set("v.save_disabled", false);
  },

  closeModal: function(component, event, helper) {
    component.set("v.isModalOpen", false);
    component.set("v.isOpen", false);
    component.set("v.isOpen2", false);
  },

  save_enable: function(component, event, helper) {
    var today = new Date();
    var newDay = new Date(component.find("estimated_closing_date").get("v.value"));
    if(component.find("estimated_closing_date").get("v.value") === ''
      || newDay <= today) {
      component.set("v.save_disabled", true);
    } else {
      component.set("v.save_disabled", false);
    }
  },

  closeModalOnFinish: function(component, event, helper) {
    var action = component.get("c.reactivateOpportunity");
    action.setParams({
      'iRecordId': component.get("v.recordId"),
      'iCloseDate': component.get("v.estimated_closing_date")
    })
    action.setCallback(this, function(response) {
      var state = response.getState();
      if(state === "SUCCESS") {
        component.set("v.isModalOpen", false);
        component.set("v.isOpen", false);
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
  }
})