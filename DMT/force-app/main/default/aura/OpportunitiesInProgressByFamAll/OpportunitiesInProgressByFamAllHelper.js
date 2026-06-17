({
	getTableData: function (cmp) {
		var accountId = cmp.get("v.idAcc");
        var familyProd = cmp.get("v.famParamAll");
        var country = cmp.get("v.country");
        var relatedOpps = cmp.get("c.getRelatedOpportunities");

        relatedOpps.setParams({
    		"accId" : accountId,
            "family": familyProd,
            "country" : country
    	});

        relatedOpps.setCallback(this, function(response){
    		if(response.getState() === "SUCCESS"){
                var resultData = JSON.parse(response.getReturnValue());
            	cmp.set("v.data", resultData);
            }
        });
        $A.enqueueAction(relatedOpps);
	},
    navigateGoBackAccount : function(cmp, event, helper) {
        cmp.find("nav").navigate({
            type: "standard__recordPage",
            attributes: {
                recordId: cmp.get("v.idAcc"),
                objectApiName: "PersonAccount",
                actionName: "view"
            }
        });
    },
    navigateGoBackFamilyDummy: function(cmp, event, helper) {
        // New version since api 43, cambiado a nombre dummy porque da fallos por caché, vuelta a la versión del e.force:navigateToCMP
        cmp.find("nav").navigate({
            type: "standard__component",
            attributes: {
                componentName: "c__ViewFamilySection" },
            state: {
                c__familyChecked: cmp.get("v.famParamAll"),
                c__recordId: cmp.get("v.idAcc")
            }

        });
    },
    navigateGoBackFamily : function(cmp, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:ViewFamilySection",
            componentAttributes: {
                familyChecked: cmp.get("v.famParamAll"),
                recordId: cmp.get("v.idAcc")
            }
        });
        evt.fire();
    }
})