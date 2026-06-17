({
    doInit: function (component, event, helper) {
        var price = component.get('v.price');
        var event = component.getEvent('onPriceSelected');
        event.setParams({
            selectedPrice: price
        });
        event.fire();
        helper.getPricingDetailRecord(component, event);
    }
})