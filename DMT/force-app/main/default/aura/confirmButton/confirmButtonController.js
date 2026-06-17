({
    init : function(component, event, helper) {
        component.set('v.isOpen', true);
        var recordId = component.get('v.inputAttributes').recordId;
        var flow = component.find('Confirm_Opportunity_is_Correct');
        flow.startFlow('Confirm_Opportunity_is_Correct', [{ name: 'recordId', type: 'String', value: recordId }]);

    },

    closeFlowModal : function(component, event, helper) {
        component.set("v.isOpen", false);
    },

    closeModalOnFinish : function(component, event, helper) {
        if( event.getParam('status') === "FINISHED" ) {
            component.set("v.isOpen", false);
            $A.get('e.force:refreshView').fire();
        }
    }
})