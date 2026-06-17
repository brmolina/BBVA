({
    afterScriptsLoaded : function(component, event, helper) {
        //alert('v. 01.12.02');
        component.set("v.ready", true);
        helper.createChart(component);
    },
    navigateToMyComponent : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:DES_CustomReportTable_ExpRevenuesByCountry",
            componentAttributes: {
                recordId : component.get("v.recordId")
            }
        });
        evt.fire();
    }
})