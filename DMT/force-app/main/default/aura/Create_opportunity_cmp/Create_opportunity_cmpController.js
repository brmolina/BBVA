({
    doInit: function(component,event,helper){
        helper.getRTName(component,event,helper);
        helper.getQuestions(component,event,helper);
        helper.fetchQuestionsForm(component,event,helper);
        helper.completeDays(component,event,helper);
    },
    cancelForm: function(component, event) {
        // Close the action panel
        var dismissActionPanel = $A.get('e.force:closeQuickAction');
        dismissActionPanel.fire();
    },
    handleChangeDisclosure: function(component,event,helper) {
        var selectedOptionValue = event.getParam("value");
        component.set("v.disclosureVal", selectedOptionValue);
        if (selectedOptionValue !== $A.get("$Label.c.DES_OP_Inside")) {
            component.set("v.form1Val", '');
            component.set("v.form2Val", '');
        }
    },
    saveForm: function(component, event, helper) {
        helper.newOpp(component, event);
        var showErrors = component.get("v.showError");
        if(showErrors === false){
            // Figure out which action was called
            var actionClicked = event.getSource().getLocalId();
            // Fire that action
            var navigate = component.get("v.navigateFlow");
            navigate(actionClicked);
        }
    }
})