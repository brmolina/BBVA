({
    doInit: function(component, event, helper) {
        var action = component.get("c.getWave");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                if(response.getReturnValue()==='false') {
                    component.set("v.typeResult", "false");
                } else if(response.getReturnValue().includes("progress")) {
                    component.set("v.result", response.getReturnValue().replace("progress", ""));
                    component.set("v.typeResult", "progress");
                } else if(response.getReturnValue().includes("scheduled")) {
                    component.set("v.result", response.getReturnValue().replace("scheduled", ""));
                    component.set("v.typeResult", "scheduled");
                }
                console.log(response.getReturnValue());
            }
            else {
                component.set("v.typeResult", "false");
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
    },

    closeFlowModal : function(component, event, helper) {
        component.set("v.isOpen", false);
    },

    closeModalOnFinish : function(component, event, helper) {
        if( event.getParam('status') === "FINISHED" ) {
            component.set("v.isOpen", false);
            $A.get('e.force:refreshView').fire();
        }
    },
    NPSsetDates : function (component, event, helper)  {
        component.set('v.isOpen', true);
        var flow = component.find('NPS_Wave_Dates');
        flow.startFlow('NPS_Wave_Dates');
    }
})