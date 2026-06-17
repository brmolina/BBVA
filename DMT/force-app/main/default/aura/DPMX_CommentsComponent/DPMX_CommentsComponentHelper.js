({
    doInit: function(cmp, evt, helper) {
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
                console.log(result);
                cmp.set('v.solicitorName', result.solicitorName);
                cmp.set('v.solicitorComment', result.solicitorComment);
                cmp.set('v.solicitorDate', result.solicitorDate);
                cmp.set('v.status', result.status);
                cmp.set('v.authorizatorName', result.authorizatorName);
                cmp.set('v.authorizatorComment', result.authorizatorComment);
                cmp.set('v.authorizatorrDate', result.authorizatorrDate);
            }
        }); 
        $A.enqueueAction(action);
    },
    showToast: function(type, title, message) {
        var toastEvent = $A.get('e.force:showToast');
        toastEvent.setParams({
            title: title,
            message: message,
            duration: 5000,
            key: 'info_alt',
            type: type,
            mode: 'dismissible'
        });
        toastEvent.fire();
    }
})