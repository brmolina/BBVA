({
    callWsWorkflow: function (component, event, helper) {
        var idRecord = component.get('v.inputAttributes').recordId;
        var action = component.get("c.callWsRegisterWorkflow");

        action.setParams({
            oppId: idRecord
        });

        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var msg = response.getReturnValue().split('#');
                helper.showToast(component, event, helper, msg[0], msg[1]);
                helper.closeModal(component, event, helper);

            } else /*if (state === "ERROR")*/ {
                // generic error handler
                var errors = response.getError();
                if (errors) {
                    console.log("Errors: ", errors);
                    if (errors[0] && errors[0].message) {
                        helper.showToast(component, event, helper, 'error', 'Workflow service call error: ' + errors[0].message);
                        helper.closeModal(component, event, helper);
                    }
                } else {
                    helper.showToast(component, event, helper, 'error', 'Workflow service call failed');
                    helper.closeModal(component, event, helper);
                }
            }
            component.set('v.showspinner', false);
        });

        $A.enqueueAction(action);
    },

    showToast: function (component, event, helper, msgType, msg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            // "title": "Success!"
            "type": msgType,
            "message": msg
        });
        toastEvent.fire();
    },

    closeModal: function (component, event, helper) {
        component.set('v.displaymodal', false);
    }
})