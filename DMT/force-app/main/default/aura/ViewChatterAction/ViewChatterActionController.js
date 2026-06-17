({
    doInit : function(component, event, helper) {
        helper.loadChatterContext(component);
    },

    toggleWidget : function(component, event, helper) {
        var currentStatus = component.get("v.isExpanded");
        component.set("v.isExpanded", !currentStatus);
    }
})