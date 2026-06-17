({
    doInit: function(cmp, event, helper) {
        helper.doInit(cmp, event, helper);
    },
    handleFieldChange: function(cmp, event, helper) {
        helper.handleFieldChange(cmp, event, helper);
    },
    handleOnSubmit: function(cmp, event, helper) {
        helper.handleOnSubmit(cmp, event, helper);
    },
    handleCancel: function(cmp, event, helper) {
        helper.closePanel();
    }
})