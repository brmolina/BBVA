({
    doInit : function(component, event, helper) {
        helper.gtInitialData(component);
        helper.gtRelatedTemplate(component);
    },
    changeOppProductISOCode : function(component, helper) {
        helper.changeISOCode(component);
    },
    saveForm: function(component, event, helper) {
        component.set("v.saveClicked", true);
        if(component.get("v.templateId") != null) {
            helper.deleteTemplate(component, component.get("v.templateId"));
        }
        helper.changeISOCode(component);
        var showErrors = component.get("v.showError");
        if(showErrors === false){
            console.log('EXCEPTION : ', showErrors);
        }
    }
})