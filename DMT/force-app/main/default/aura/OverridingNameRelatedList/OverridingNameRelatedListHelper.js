({
    checkNBC: function(cmp){
        var action = cmp.get("c.checkNBC");
        action.setParams({
            "idVisit": cmp.get("v.recordId")
        });
        action.setCallback(this, function(response) {

            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
               // set current user information on userInfo attribute
                cmp.set("v.visitOfNBC", storeResponse);
            }
        });
        $A.enqueueAction(action);
    }
})