({
	doInit : function(cmp, event, helper){
		var accountId = cmp.get("v.recordId");
        var relatedVisits = cmp.get("c.getVisitInfo");
        var countryName = cmp.get("v.country");
        relatedVisits.setParams({
    		"accId" : accountId,
    		"country" : countryName
    	});

        relatedVisits.setCallback(this, function(response){
    		if(response.getState() === "SUCCESS"){
                var resultData = JSON.parse(response.getReturnValue());
            	cmp.set("v.data", resultData);
            }
        });

         $A.enqueueAction(relatedVisits);
	}
})