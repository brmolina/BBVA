({
	doInit: function(component, event, helper) {
        //helper.showBlockUnblock(component, event, helper);
		helper.chooseFunction(component, event, helper);
	},

    callFlow : function (component, event, helper) {
        component.set('v.isOpen', true);
        var flow = component.find('flowName');
        if(component.get('v.Custom_notification')) {
            flow.startFlow('accountPlanningNotificationCenter');
        }
    },
    
    closeFlowModal : function(component, event, helper) {
        component.set("v.isOpen", false);
    },
    
    closeModalOnFinish : function(component, event, helper) {
        if(event.getParam('status') === "FINISHED") {
            component.set("v.isOpen", false);
            $A.get('e.force:refreshView').fire();
        }
    }    
})