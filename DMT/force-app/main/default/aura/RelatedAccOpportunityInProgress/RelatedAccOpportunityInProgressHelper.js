({
	getTableData: function (cmp) {
		var accountId = cmp.get('v.recordId');
        var relatedOpps = cmp.get('c.getRelatedOpportunities');

        relatedOpps.setParams({
            'tableSize' : '5',
    		'accId' : accountId
    	});

        relatedOpps.setCallback(this, function(response){
    		if(response.getState() === 'SUCCESS'){
                var resultData = JSON.parse(response.getReturnValue());
            	cmp.set('v.data', resultData);
            }
        });
        $A.enqueueAction(relatedOpps);
	}
})