({
	doInit: function(cmp, evt, helper) {
		helper.callServerData(cmp, evt, helper);
		helper.revenuesInfo(cmp,evt,helper);
	},
  	navigateToFamilySection : function(cmp, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        var idFamily = event.target.id;

        evt.setParams({
            componentDef : "c:ViewFamilySection",
            componentAttributes: {
                recordId : cmp.get("v.recordId"),
                familyChecked : idFamily,
                filial : cmp.get("v.filial")
            }
        });
        evt.fire();
    }
});