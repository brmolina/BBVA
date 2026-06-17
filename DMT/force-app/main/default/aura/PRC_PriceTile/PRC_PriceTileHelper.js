({
    runPriceClick: function (component, event) {
        var price = component.get('v.price');
        var eventPRC = component.getEvent('onPriceSelected');
        eventPRC.setParams({
            selectedPrice: price
        });
        eventPRC.fire();
    }
})