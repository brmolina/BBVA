({
    getPricingDetailRecord: function (component, event) {
        var action = component.get("c.getPricingDetail");
        var oppId = component.get("v.opportunityId");

        action.setParams({ oppId: oppId });

        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.pricingDetailRecord", response.getReturnValue());
                console.log('>>>>>> PRC_UniquePriceTile - pricingDetailRecord loaded: ' + response.getReturnValue());
            } else if (state === "ERROR") {
                // generic error handler
                var errors = response.getError();
                if (errors) {
                    console.log("Errors", errors);
                    if (errors[0] && errors[0].message) {
                        throw new Error("Error: " + errors[0].message);
                    }
                } else {
                    throw new Error("Unknown Error");
                }
            }
        });

        $A.enqueueAction(action);
    }
})