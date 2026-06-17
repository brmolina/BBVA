({
    init: function(component, event, helper) {
      component.set('v.isModalOpen', true);
      component.set('v.isOpen', true);
      component.set("v.recordId", component.get("v.inputAttributes").recordId);
    },

    handleSubmit: function(component, event, helper) {
        event.preventDefault();       // stop the form from submitting
        var fields = event.getParam('fields');
        var action = component.get("c.rejectClient");
        action.setParams({
            "recordId": component.get("v.recordId"),
            "temp": fields
        });
        action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
            component.set("v.isModalOpen", false);
            component.set("v.isOpen", false);
            window.location.reload();
        } else {
            console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
        }
        });
        $A.enqueueAction(action);
    },

    closeModal: function(component, event, helper) {
        component.set("v.isModalOpen", false);
        component.set("v.isOpen", false);
    },

  })