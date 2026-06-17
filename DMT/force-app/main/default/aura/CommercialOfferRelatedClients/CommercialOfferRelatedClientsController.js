({
	doInit : function(component, event, helper) {
       helper.getRelatedClients(component, event, helper)
    },

    navigateRecord: function(component, event, helper) {
        var target = event.target.id;
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId" : target
        });
        navEvt.fire();
    },

    navigateToMyComponent : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:CommercialOfferRelatedClients",
            componentAttributes: {
	            recordId : component.get("v.recordId"),
            	detailForm : 'true'
	        }
        });
        evt.fire();
    }

})