({
	doInit : function(cmp, event, helper){
        helper.getTableData(cmp);
	},

	navigateToMyComponent : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:NextVisitsByFamilyAll",
            componentAttributes: {
	            idAcc : component.get("v.recordId"),
                famParamAll : component.get("v.familyParam"),
                country : component.get("v.country"),
                breadcrumbsActive : component.get("v.breadcrumbsActive")
	        }
        });
        evt.fire();
    }

})