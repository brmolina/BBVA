({
    handleSave: function(cmp, evt, helper) {
        var action = cmp.get('c.deniedFormalize');
        console.log(cmp.find("commentarioTxt").get("v.value"));
        console.log(cmp.get('v.recordId'));
        action.setParams({
            'recordId': cmp.get('v.recordId'),
            'commentarioTxt': cmp.find("commentarioTxt").get("v.value")
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('INIT');
            console.log(state);
            if (state === 'SUCCESS') {
                console.log('SUCCESS');
                var result = response.getReturnValue();
                if (result.statusAuth) {
                    helper.updateoast();
                    helper.handleClose(cmp, evt, helper);
                } else {
                    helper.showToast();
                }
            } else {
                helper.errorToast();
            }
            cmp.destroy();
        });
        $A.enqueueAction(action);
    },
    checkComment: function(cmp) {
        var commentarioTxt = cmp.find("commentarioTxt").get("v.value");
        if (commentarioTxt.length != 0) {
            cmp.set("v.disableSubmitBtn", false);
        } else {
            cmp.set("v.disableSubmitBtn", true);
        }
    },
    errorToast: function() {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": 'Ha ocurrido un error al denegar la formalización.',
        });
        toastEvent.fire();
    },
    updateoast: function() {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": "Esta formalización se ha denegado.",
            "type": "success",
        });
        toastEvent.fire();
    },
    showToast: function() {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": "Esta formalización se ha denegado.",
        });
        toastEvent.fire();
    },
    handleClose: function(cmp, evt, helper) {
        cmp.destroy();
    }
})