({
    doInit : function(component, event, helper) {
        helper.onInit(component, event, helper);
        helper.salesInit(component, event, helper);
        helper.assetType(component, event, helper);
    },

    setSales : function(component, event, helper) {
        helper.setSalesHelper(component,event,helper);
    },

    handleSubmit : function(component, event, helper) {
        var primary = component.get('v.primaryChild');
        var secondary = component.get('v.secondaryChild');
        if(secondary && primary) {
            helper.saveHelper(component, event, helper);
        }
    },

    handleDelete : function(component, event, helper) {
        helper.onHandleDelete(component, event, helper);
    },
    changeSaveField : function(component, event, helper) {
        helper.changeSaveField(component, event, helper);
    }
})