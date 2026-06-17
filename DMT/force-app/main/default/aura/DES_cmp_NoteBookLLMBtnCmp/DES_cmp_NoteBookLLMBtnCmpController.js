({
    doInit : function(component, event, helper) {
        var url = $A.get("$Label.c.DES_lb_SupportWUT");
        const action = component.get("c.surveyNotification");
        console.log("URL: " + url);
        action.setParams({
            survey: "SupportWUP"
        });

        action.setCallback(this, function(response) {
            const state = response.getState();
            if (state === "SUCCESS") {
                console.log("Platform Event publicado");
            } else {
                const errors = response.getError();
                console.error("Error publicando PE", errors);
            }
        });

        $A.enqueueAction(action);
        window.open(url, '_blank');
        
    }
})