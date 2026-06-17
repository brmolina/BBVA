({
	doInit: function(component, event, helper) {

        var action = component.get("c.setLastVisit");
        action.setParams({
            "template": component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                if(response.getReturnValue())
                	location.reload();
            }
            else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
	}
})