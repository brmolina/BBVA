({

    gtGAAccountId: function (cmp) {
    	var gaId = cmp.get('v.recordId');
        var accountId = cmp.get('c.gtGAAccountId');

        accountId.setParams({
    		'gaId' : gaId
    	});

        accountId.setCallback(this, function(response) {
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
		var qType = cmp.get('v.qType');
        console.log('accId: ' + accId);
        console.log('qType: ' + qType);
        var relatedOpps = cmp.get('c.getRelatedOpportunities');

        relatedOpps.setParams({
            'tableSize' : cmp.get('v.tableSize'),
    		'accId' : accId,
            'qType' : qType
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