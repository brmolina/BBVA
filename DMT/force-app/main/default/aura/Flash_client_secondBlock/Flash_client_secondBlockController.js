({
    init: function(component, event, helper) {
        
        helper.QueryMethod(component, event,"Directa");
    },
    handleActive : function (component, event,helper) {
        // This will contain the string of the "value" attribute of the selected option
        var selectedOptionValue = event.getParam("value");
        helper.QueryMethod(component, event,selectedOptionValue);
        
    }
})