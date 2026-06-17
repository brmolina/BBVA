({
    getStatusWorkflow: function (component, event, helper) {
        var action = component.get("c.getStatusWorkflow");

        action.setParams({ oppId: component.get("v.recordId") });

        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state !== "SUCCESS") {
                // generic error handler
                var errors = response.getError();
                if (errors) {
                    console.log("Errors", errors);
                    if (errors[0] && errors[0].message) {
                        helper.showToast(component, event, helper, 'error', 'Workflow Status service call error: ' + errors[0].message);
                    }
                } else {
                    helper.showToast(component, event, helper, 'error', 'Workflow Status service call failed');
                }
            }
            // se muestra el estado tanto si funcionó la llamada como si falló (se mostrará el estado que hubiera antes)
            component.set("v.oppId", component.get("v.recordId"));
        });

        $A.enqueueAction(action);
    },

    showToast: function (component, event, helper, msgType, msg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": msgType,
            "message": msg
        });
        toastEvent.fire();
    }
})