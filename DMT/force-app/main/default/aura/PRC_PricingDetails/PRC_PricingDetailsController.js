({
    doinit: function (component, event, helper) {
        console.log('>>> do init del details');
        var oppliidloaded = helper.loadrecords(component);
        oppliidloaded.then($A.getCallback(function (resolve) {
            console.log('>>> ApriceDetails id loaded');
            return helper.checkvisibility(component);
        })).then($A.getCallback(function (resolve) {
            helper.mitigantVisibility(component);
            component.set('v.loaded', true);
            console.log('>>> PricingDetails id: ' + component.get('v.priceDetails').id);
        }));
    }
})