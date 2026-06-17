({
    selectedTab: function (component, operation) {
        var evento = component.getEvent("operationSelectedEVT");
        evento.setParams({
            value: operation
        });
        evento.fire();
    }
})