({
	afterScriptsLoaded: function (component, event, helper) {
		component.set("v.ready", true);
        helper.createChart(component, helper);
	},

    navigateToMyComponent: function (component, event, helper) {
        var nav = $A.get("e.force:navigateToComponent");
        nav.setParams({
            componentDef: "c:VisitsPieReport",
            componentAttributes: {
                recordId: component.get("v.recordId"),
                familyParam: component.get("v.familyParam")
            }
        });
        nav.fire();
    }
})