({
    doInit: function(cmp, event, helper) {
        var action = cmp.get('c.getInitialData');
        action.setParams({
            'recordId': cmp.get('v.recordId')
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('INIT');
            if (state === 'SUCCESS') {
                console.log('SUCCESS');
                var result = response.getReturnValue();
                console.log(result.userLst);
                cmp.set('v.userLst', result.userLst);
            } else {
                helper.errorToast();
            }
        });
        $A.enqueueAction(action);
    },
    handleSave: function(cmp, evt, helper) {
        console.log(cmp.find("existingUser").get("v.value"));
        var action = cmp.get('c.updateAuth');
        console.log('SUCCESS');
        action.setParams({ 
            'recordId': cmp.get('v.recordId'),
            'userId': cmp.find("existingUser").get("v.value"),
        })
        console.log('SUCCESS');
        action.setCallback(this, function(response) {
            console.log('SUCCESS');
            console.log(response);
            var state = response.getState();
            console.log(state);
            if (state === 'SUCCESS') {
                console.log('SUCCESS');
                var result = response.getReturnValue();
                console.log(result.sendReport);
                helper.updateoast();
                let appEvent = $A.get('e.c:DPMX_SimulatorRefresh_evt');
                appEvent.setParams({
                    'recordId': cmp.get('v.recordId')
                });
                appEvent.fire();
                cmp.destroy();
            } else {
                console.log('else');
                helper.errorToast();
            }
        });
        $A.enqueueAction(action);
        console.log('END');

    },
    errorToast: function() {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": 'Ha ocurrido un error al reasignar.',
        });
        toastEvent.fire();
    },
    updateoast: function() {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": "Esta Autorización se ha reasignado.",
            "type": "success",
        });
        toastEvent.fire();
    },
    handleClose: function(cmp, evt, helper) {
        cmp.destroy();
    }
})