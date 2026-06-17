({

    gtAPAccountId: function (cmp) {
    	var apId = cmp.get('v.recordId');
        var accountId = cmp.get('c.gtAPAccountId');	
        
        accountId.setParams({
    		'apId' : apId
    	});
        
        accountId.setCallback(this, function(response){
    		if(response.getState() === 'SUCCESS'){
                var resultData = response.getReturnValue();
                console.log('resultData: ' + resultData);
            	cmp.set('v.accId', resultData);
                this.getTableData(cmp);
            }
        });	
        $A.enqueueAction(accountId);
    },
	
    getTableData: function (cmp) {
		var accId = cmp.get('v.accId');
        console.log('accId: ' + accId);
        var relatedOpps = cmp.get('c.getRelatedOpportunities');	
        
        relatedOpps.setParams({
            'tableSize' : cmp.get('v.tableSize'),
    		'accId' : accId
    	});
        
        relatedOpps.setCallback(this, function(response){
    		if(response.getState() === 'SUCCESS'){
                var resultData = JSON.parse(response.getReturnValue());
                console.log('resultData 2: ' + resultData);
            	cmp.set('v.data', resultData);    
            }
        });	
        $A.enqueueAction(relatedOpps);
	}
})