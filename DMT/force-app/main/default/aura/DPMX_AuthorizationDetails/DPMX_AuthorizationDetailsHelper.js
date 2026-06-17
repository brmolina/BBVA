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
                console.log(result.authInternational);
                cmp.set('v.authTypeName', result.authTypeName);
                cmp.set('v.authSolicitudeName', result.authSolicitudeName);
                cmp.set('v.authBai', result.authBai);
                cmp.set('v.authCredit', result.authCredit);
                cmp.set('v.authDebit', result.authDebit);
                cmp.set('v.authInternational', result.authInternational);
                cmp.set('v.authProfitability', result.authProfitability);
                cmp.set('v.authResult', result.authResult);
                cmp.set('v.authFamily', result.authFamily);
                cmp.set('v.isGs', result.isGs);
                console.log(result.authCredit);

                cmp.set('v.creditBase', result.creditBase);
                cmp.set('v.debitBase', result.debitBase);
                cmp.set('v.internationalBase', result.internationalBase);
                cmp.set('v.rentaBase', result.rentaBase);
                cmp.set('v.baiBase', result.baiBase);
            } 
        });
        $A.enqueueAction(action);
    }
})