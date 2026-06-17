({
	doInit: function(cmp, evt, helper) {
        var action = cmp.get('c.getInitialData');
        console.log(cmp.get('v.recordId'));
        action.setParams({
            'recordId': cmp.get('v.recordId')
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('INIT');
            console.log(state);
            if (state === 'SUCCESS') {
                console.log('SUCCESS');
                var result = response.getReturnValue();
                cmp.set('v.name', result.name);
                cmp.set('v.disableBtn', !result.disableBtn);
            }
        });
        $A.enqueueAction(action);
    }, 
	handleDecline: function(cmp, evt, helper) {
        console.log('ASD');
		let attr = {
            'recordId': cmp.get('v.recordId')
        };
        helper.loadComponent(cmp, event, helper, 'DPMX_AuthorizationDeny', attr).then($A.getCallback(newComponent => {
            let body = [];
            body.push(newComponent);
            cmp.set('v.body', body);
        }));
    },
	handleReasign: function(cmp, evt, helper) {
        console.log('ASD');
		let attr = {
            'recordId': cmp.get('v.recordId')
        };
        helper.loadComponent(cmp, event, helper, 'DPMX_AuthorizationReassign', attr).then($A.getCallback(newComponent => {
            let body = [];
            body.push(newComponent);
            cmp.set('v.body', body);
        }));
    },
	handleAccept: function(cmp, evt, helper) {
		console.log('ASD');
		let attr = {
            'recordId': cmp.get('v.recordId')
        };
        helper.loadComponent(cmp, event, helper, 'DPMX_AuthorizationRequest', attr).then($A.getCallback(newComponent => {
            let body = [];
            body.push(newComponent);
            cmp.set('v.body', body);
        }));
    },
    loadComponent: function(cmp, event, helper, cmpName, cmpAttr) {
        return new Promise($A.getCallback(function(resolve, reject) {
            $A.createComponent(
                'c:' + cmpName, cmpAttr,
                function(newCmp, status, errorMessage) {
                    if (status === 'SUCCESS') {
                        resolve(newCmp);
                    } else if (status === 'INCOMPLETE' || status === 'ERROR') {
                        helper.showToast('Error', 'error', errorMessage);
                    }
                }
            );
        }));
    }
})