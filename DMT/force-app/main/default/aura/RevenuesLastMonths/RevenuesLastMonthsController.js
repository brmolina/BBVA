({
    afterScriptsLoaded: function (component, event, helper) {
        component.set("v.ready", true);
        helper.createChart(component, helper);
    },
    navigateToMyComponent: function (component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef: "c:RevenuesLastMonthsReport",
            componentAttributes: {
                recordId: component.get("v.recordId"),
                familyParam: component.get("v.familyParam"),
                monthsToDisplay: component.get("v.monthsToDisplay")
            }
        });
        console.log('familyParam controler js' + component.get("v.familyParam"));
        evt.fire();
    }
})