({
    loadLocalClient: function(component) {
        component.set("v.isLoading", true);
        component.set("v.errorMessage", null);

        const action = component.get("c.getLocalClientId");
        action.setParams({ clientId: component.get("v.recordId") });

        action.setCallback(this, function(response) {
            component.set("v.isLoading", false);

            if (response.getState() === "SUCCESS") {
                const lcId = response.getReturnValue();
                component.set("v.localClientId", lcId);
            } else {
                const errs = response.getError();
                let msg = "Error obteniendo Local Client.";
                if (errs && errs[0] && errs[0].message) msg = errs[0].message;
                component.set("v.errorMessage", msg);
            }
        });

        $A.enqueueAction(action);
    }
})