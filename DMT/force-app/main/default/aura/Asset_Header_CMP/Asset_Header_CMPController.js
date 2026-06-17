({
    doInit : function(component, event, helper) {
        helper.onInit(component, event, helper);
    },

    closeModal: function(component, event, helper) {
        helper.closeModal(component, event, helper);
    },

    handleSave: function(component, event, helper) {
        helper.saveHelper(component, event, helper);
    },

    handleSuccess: function(component, event, helper) {
        helper.handleSuccess(component, event, helper);
    },

    handleSaveNew: function(component, event, helper) {
        helper.saveHelper(component, event, helper);
        $A.get('e.force:refreshView').fire();
    },

})