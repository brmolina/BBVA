({
    runPriceClick: function(component,event) {
        var price = component.get('v.price');
        var eventPrice = component.getEvent('onPriceSelected');
        eventPrice.setParams({
            selectedPrice:price
        });
        eventPrice.fire();
    }
})