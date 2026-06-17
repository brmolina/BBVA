({
	doInit : function(cmp, event, helper){
		var accountId = cmp.get("v.recordId");
        var relatedAlerts = cmp.get("c.getAlertInfo");
        relatedAlerts.setParams({
    		"accId" : accountId
    	});

        relatedAlerts.setCallback(this, function(response){
    		if(response.getState() === "SUCCESS"){
                var resultData = JSON.parse(response.getReturnValue());
            	cmp.set("v.data", resultData);
            }
        });

         $A.enqueueAction(relatedAlerts);
	}
})