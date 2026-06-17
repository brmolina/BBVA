({
	doInit : function(component, event, helper) {   

        // Retrieve contacts during component initialization
        var atributoCuenta = component.find("cuenta");
        var action = component.get("c.getAccountData");
        action.setParams({
            "accountId": component.get("v.recordId")
        });
        
        // Register the callback function
        action.setCallback(this, function(response) {
            // Set the component attributes using values returned by the API call
            	console.log(response.getState());
            	console.log(response.getReturnValue());
                component.set("v.cuenta", response.getReturnValue());  
        });
        // Invoke the service
        $A.enqueueAction(action);

    }
})