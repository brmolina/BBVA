({
    doInit : function(component, event, helper) {
        var action=component.get("c.getBPPrivacy");
        var idAP=component.get("v.recordId");
        action.setParams({
            "idAP":idAP
                        });
        action.setCallback(this,function(response) {
            var state=response.getState();
            if(state==="SUCCESS") {
                 var storeResponse = response.getReturnValue();
                 component.set("v.ispublic",storeResponse);
            }
        });
        $A.enqueueAction(action);
    },

})