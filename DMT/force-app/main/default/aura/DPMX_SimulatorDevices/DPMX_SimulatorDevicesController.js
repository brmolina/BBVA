({
    doInit: function(cmp, event, helper) {
        helper.doInit(cmp, event, helper);
    },
    handleOnCheckTerminal: function(cmp, event, helper) {
        helper.handleOnCheckTerminal(cmp, event, helper);
    },
    handleOnCheckPinpad: function(cmp, event, helper) {
        helper.handleOnCheckPinpad(cmp, event, helper);
    },
    handleOnCheckPOS: function(cmp, event, helper) {
        helper.handleOnCheckPOS(cmp, event, helper);
    },
    handleOnCheckRecCharg: function(cmp, event, helper) {
        helper.handleOnCheckRecCharg(cmp, event, helper);
    },
    handleOnCancel: function(cmp, event, helper) {
        helper.destroyCmp(cmp, event, helper);
    },
    handleOnSave: function(cmp, event, helper) {
        helper.handleOnSave(cmp, event, helper);
    },
    onUpdateField: function(cmp, event, helper) {
        helper.onUpdateField(cmp, event, helper);
    }
})