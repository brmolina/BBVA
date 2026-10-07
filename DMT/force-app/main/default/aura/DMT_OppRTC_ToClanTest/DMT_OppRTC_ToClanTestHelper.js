({
    execute : function(component) {

        var action = component.get("c.sendToClan");

        action.setParams({
            opportunityId : component.get("v.recordId")
        });

        action.setCallback(this, function(response) {

            var state = response.getState();

            if(state === "SUCCESS") {

                $A.get("e.force:showToast")
                    .setParams({
                        title: "Correcto",
                        message: "Proceso enviado correctamente.",
                        type: "success"
                    })
                    .fire();

            } else {

                var errors = response.getError();

                $A.get("e.force:showToast")
                    .setParams({
                        title: "Error",
                        message: errors && errors[0] ? errors[0].message : "Ha ocurrido un error.",
                        type: "error"
                    })
                    .fire();
            }

            $A.get("e.force:closeQuickAction").fire();
        });

        $A.enqueueAction(action);
    }
})