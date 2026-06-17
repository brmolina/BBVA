({
    doInit : function(component, event, helper) {
        helper.onInit(component,event,helper);
    },
    onPriceSelected: function(component,event,helper) {
        var selectedPrice = event.getParam('selectedPrice');
        component.set('v.selectedPrice',selectedPrice);
    },
    onMatrixSelected: function(component,event,helper) {
        helper.setMatrixSelected(component,helper);
    },
    savePrice: function(component,event,helper) {
        helper.saveSelectedPrice(component,event,helper);
    }



})