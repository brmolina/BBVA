({
    doInit: function(cmp, event, helper) {
        var action = cmp.get('c.getData');
        action.setParams({
            'dynamicPricing': cmp.get('v.dynamicPricing')
        })
    },
    closeModal: function(cmp) {
        cmp.destroy();
    },
    saveModal: function(cmp) {
        console.log(cmp.get('v.dynamicPricing'));
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                cmp.set('v.dynamicPricingUpsert', result.dynamicPricingUpsert);
                cmp.set('v.initalValues', result.dynamicPricingUpsert);
                cmp.set('v.isCustom', result.isCustom);
            } else if (state === 'INCOMPLETE') {
                console.log('INCOMPLETE', response);
            } else if (state === 'ERROR') {
                console.log('ERROR', response.getError());
            }
        });
        $A.enqueueAction(action);
        cmp.destroy();
    },
})