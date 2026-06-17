({
	afterScriptsLoaded: function (component, event, helper) {
        component.set("v.ready", true);
        helper.createChart(component, helper);
        helper.getDataTable(component, helper);
    },

    navigateToMyComponent : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:CommOfferRevenues",
            componentAttributes: {
	            recordId : component.get("v.recordId"),
            	showViewDetails : 'true'
	        }
        });
        evt.fire();
    }
})