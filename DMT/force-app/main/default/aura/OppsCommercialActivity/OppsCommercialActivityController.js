({
	doInit : function(cmp, event, helper) {
		var accountId = cmp.get('v.recordId');
        var relatedOpps = cmp.get('c.getOppInfo');
        var countryName = cmp.get('v.country');
        relatedOpps.setParams({
    		'accId' : accountId,
    		'country' : countryName
    	});

        relatedOpps.setCallback(this, function(response) {
    		if(response.getState() === 'SUCCESS'){
                var resultData = JSON.parse(response.getReturnValue());
            	cmp.set('v.data', resultData);
            }
        });
         $A.enqueueAction(relatedOpps);
	}
})