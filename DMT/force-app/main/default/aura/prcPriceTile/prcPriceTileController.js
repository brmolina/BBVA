({
    doInit : function(component, event, helper) {
        if (component.get('v.selected')) {
            var selectedInit = component.find("nonPaying");
            console.log(selectedInit);
        $A.util.addClass(selectedInit,'selected');
            helper.runPriceClick(component,event);
        }

    },
    onPriceClick: function(component, event, helper) {
        helper.runPriceClick(component,event);
    }
})