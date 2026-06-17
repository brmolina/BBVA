({
    afterScriptsLoaded : function(component, event, helper) {
    	//alert('v. 01.13.13');
        component.set("v.ready", true);
        helper.createChart(component);
    },
    navigateToMyComponent : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:DES_CustomReportTable_PRevByProd",
            componentAttributes: {
                recordId : component.get("v.recordId")
            }
        });
        evt.fire();
    }
})