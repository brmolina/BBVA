({
    doInit: function(cmp, event, helper) {
        helper.setInitialValues(cmp, event, helper);
		helper.previousChecks(cmp, event, helper);
		helper.getProfitabilitySheets(cmp, event, helper);
    },
    handleMoveOptionChange: function(cmp, evt, helper) {
        helper.handleMoveOptionChange(cmp, evt, helper);
    },
    handleOnSubmit: function(cmp, event, helper) {
		helper.handleOnSubmit(cmp, event, helper);
    },
    handleCancel: function(cmp, event, helper) {
        helper.destroyCmp(cmp, event, helper);
    }
})