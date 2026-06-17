({
	getRecordHasAnalysisId: function(component, event, helper) {
    	var recordId = component.get("v.recordId");
        var action = component.get("c.getAccountHasAnalysis"); 
        action.setParams({"account":recordId});
        
        action.setCallback(this, function (response) { 
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                component.set('v.recordHasId', result); 
                var prueba = component.get("v.recordHasId");
                console.log(prueba);
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