({
	getTableData: function (cmp) {
		var accountId = cmp.get("v.recordId");
        var familyProd = cmp.get ("v.familyParam");
        var country = cmp.get ("v.country");
        var relatedOpps = cmp.get("c.getRelatedOpportunities");
        console.log ("family = "+familyProd);
        console.log ("::::::country = " + country);
        relatedOpps.setParams({
            "tableSize" : '5',
    		"accId" : accountId,
            "family" : familyProd,
            "country" : country
    	});

        relatedOpps.setCallback(this, function(response){
    		if(response.getState() === "SUCCESS"){
                var resultData = JSON.parse(response.getReturnValue());
                cmp.set("v.data", resultData);
            }
        });
        $A.enqueueAction(relatedOpps);
	}
})