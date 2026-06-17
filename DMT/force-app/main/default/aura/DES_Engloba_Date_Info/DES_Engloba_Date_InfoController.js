({
	doInit : function(component, event, helper) {   
		//alert('v. 02.04');
        var action = component.get("c.getEnglobaData");
        
        // Register the callback function
        action.setCallback(this, function(response) {
            // Set the component attributes using values returned by the API call
            	console.log(response.getState());
            	console.log(response.getReturnValue());
                component.set("v.mensaje", response.getReturnValue());  
        });
        // Invoke the service
        
        $A.enqueueAction(action);
    }
})