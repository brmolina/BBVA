({
  doInit: function(component, event, helper) {

        var action = component.get("c.setFindCurrentApprover");
        action.setParams({
            "template": component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                if(response.getReturnValue()!=null){
                  component.set("v.IdProcess",response.getReturnValue() );
                  helper.gotoURL(component);
                  component.set("v.ShowMessage", false);
                } else {
                  component.set("v.ShowMessage", true);
                }
            }

            else {
                console.log("Failed with state: " + state);
                component.set("v.ShowMessage", true);
            }
        });
        $A.enqueueAction(action);
  }
})