({
    doInit: function (cmp, event, helper) {

        cmp.set("v.showData", false);
        let action = cmp.get("c.getClientData");
        action.setParams({
            "recordId": cmp.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                cmp.set('v.data', response.getReturnValue());
                cmp.set('v.ipClientLink', location.protocol  + "//" +  location.host + '/' + response.getReturnValue().clientId );
                cmp.set('v.ipOwnerLink', location.protocol  + "//" +  location.host + '/' + response.getReturnValue().ownerId );
            }
            else {
            }
        });
        $A.enqueueAction(action);

        var actionUser = cmp.get('c.bbvaUserCode');
        actionUser.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                cmp.set('v.codUser', response.getReturnValue());
                helper.getUrlIp(cmp, event, helper);
            }
            else {
            }
        });
        $A.enqueueAction(actionUser);



    }
})