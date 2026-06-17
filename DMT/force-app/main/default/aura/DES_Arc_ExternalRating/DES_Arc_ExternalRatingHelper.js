({
	getRatingSource: function(component, event, helper) {
    	var recordId = component.get("v.recordId");
        const editButton = '{"style":"brand","unactiveStyle":"hidden","active":' + false + '}';
        var action = component.get("c.getRatingSource"); 
        action.setParams({"account":recordId});
        
        action.setCallback(this, function (response) { 
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                component.set('v.idSelect', result); 
                component.set('v.editB', editButton); 
                component.set('v.isValidated', true); 
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                        console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action); 
    }
})