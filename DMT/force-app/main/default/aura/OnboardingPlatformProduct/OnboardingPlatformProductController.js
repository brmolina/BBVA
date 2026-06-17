({
    doInit : function(component, event, helper) {
        helper.getProductIDs(component, event, helper);
    },
    addAssetProduct : function(component, event, helper) {
        helper.addAssetProduct(component, event, helper);
    },
    handleEvent : function(component, event, helper) {
        helper.handleEvent(component, event, helper);
    },
    handleTierEvent : function(component, event, helper) {
        helper.handleTierEvent(component, event, helper);
    },
    saveAll : function(component, event, helper) {
        helper.getSecondary(component, event, helper);
    },
    saveTier : function(component, event, helper) {
        helper.saveTier(component, event, helper);
    },
    handleProductRefresh : function(component, event, helper) {
        helper.handleProductRefresh(component, event, helper);
    },
    cancelHandler : function(component, event, helper) {
        helper.cancelHandler(component, event, helper);
    }
})