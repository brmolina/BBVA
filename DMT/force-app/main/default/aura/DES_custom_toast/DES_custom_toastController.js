({
	// When a flow executes this component, it calls the invoke method
	invoke : function(component, event, helper) {
		var operation = component.get("v.operation");
        if(operation === "success") {
            helper.success(component);
        } else if (operation === "validation") {
            helper.validation(component);
        } else if(operation === "error") {
             helper.error(component);
        }
	}
})