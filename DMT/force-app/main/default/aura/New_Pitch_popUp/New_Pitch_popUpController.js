({
	init: function (component, event, helper) {
        helper.GetV(component);
        helper.StarFlow(component);
  	},
  	handleStatusChange: function (component, event) {
        if (event.getParam('status') === 'FINISHED') {
            var recordId = component.get('v.recordId');
          	var urlEvent = $A.get('e.force:navigateToSObject');
          	urlEvent.setParams({
                'recordId': recordId,
                'isredirect': 'true'
          	});
          	urlEvent.fire();
    	}
  	},
    closeFlowModal : function(component, event, helper) {
        component.set('v.isOpen', false);
        $A.get('e.force:refreshView').fire();
	}
})