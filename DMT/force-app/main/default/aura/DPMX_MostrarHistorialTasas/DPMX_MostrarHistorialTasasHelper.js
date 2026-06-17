({
    "doInit": function(cmp, evt, helper) {
        console.log('init');
        var status = cmp.get('v.status');
        console.log(cmp.get('v.businessAgentId'));
        console.log(cmp.get('v.recordId'));
        var action = cmp.get('c.getInitialData');
        action.setParams({
            'recordId': cmp.get('v.recordId'),
            'businessAgentId': cmp.get('v.businessAgentId'),
            'businessAuthorizesId': cmp.get('v.businessAuthorizesId')
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('INIT');
            console.log(state);
            if (state === 'SUCCESS') {
                console.log('SUCCESS');
                var result = response.getReturnValue();
                cmp.set('v.businessAgent', result.businessAgent);
                cmp.set('v.businessAuthorizes', result.businessAuthorizes);
                console.log(status.itemizeRates);
                for (var rate in status.itemizeRates) {
                    console.log(rate);
                    console.log(status.itemizeRates[rate]);
                    if (status.itemizeRates[rate].rateType == 'DESCUENTODEBITO') {
                        cmp.set('v.debitExist', true);
                        cmp.set('v.isGs', result.isGs);
                        if (status.itemizeRates[rate].fee.unitType == 'PERCENTAGE') {
                            cmp.set('v.debitExist', true);
                            cmp.set('v.tasaDebit', status.itemizeRates[rate].fee.percentage);
                        } else {
                            cmp.set('v.tasaDebit', status.itemizeRates[rate].fee.amount);
                        }
                        cmp.set('v.statusDebit', status.itemizeRates[rate].codeStatus);

                    } else if (status.itemizeRates[rate].rateType == 'CREDITONACIONAL') {
                        cmp.set('v.creditExist', true);
                        cmp.set('v.tasacredito', status.itemizeRates[rate].fee.percentage);
                        cmp.set('v.statuscredito', status.itemizeRates[rate].codeStatus);
                    } else if (status.itemizeRates[rate].rateType == 'CREDITOINTERNACIONAL') {
                        cmp.set('v.internationalExist', true);
                        cmp.set('v.tasaInternational', status.itemizeRates[rate].fee.percentage);
                        cmp.set('v.statusInternational', status.itemizeRates[rate].codeStatus);
                    }
                }
            }
        });
        $A.enqueueAction(action);
    },
    handleClose: function(cmp, evt, helper) {
        console.log('destroy');
        cmp.destroy();
    },
})