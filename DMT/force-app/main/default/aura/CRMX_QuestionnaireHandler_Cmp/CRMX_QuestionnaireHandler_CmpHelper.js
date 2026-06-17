({
    checkOrCreateCuestionario: function(cmp) {
        const action = cmp.get("c.getOrCreateCuestionario");
        action.setParams({ accountId: cmp.get("v.recordId") });
        action.setCallback(this, function(response) {
            const state = response.getState();
            if (state === "SUCCESS") {
                const cuestionarioId = response.getReturnValue();
                cmp.set("v.recordId", cuestionarioId);
                cmp.set("v.view", true);
            } else if (state === "ERROR") {
                cmp.set("v.view", false);
                }
            });
        $A.enqueueAction(action);
    }
})