({
    callWorkflow: function (component, event, helper) {
        component.set('v.displaySpinner', true);
        helper.callWsWorkflow(component, event, helper);
    },
    cancelWorkflowl: function (component, event, helper) {
        helper.closeModal(component, event, helper);
    }
})