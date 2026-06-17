({

    gtGAAccountId: function (cmp) {
    	var gaId = cmp.get('v.recordId');
        var accPlnId = cmp.get('c.gtGAAPId');

        accPlnId.setParams({
    		'gaId' : gaId
    	});

        accPlnId.setCallback(this, function(response){
    		if(response.getState() === 'SUCCESS'){
                var resultData = response.getReturnValue();
                console.log('resultData: ' + resultData);
            	cmp.set('v.apId', resultData);
                this.getTableData(cmp);
            }
        });
        $A.enqueueAction(accPlnId);
    },

    getTableData: function (cmp) {
		var apId = cmp.get('v.apId');
        console.log('apId: ' + apId);
        var relatedRec = '';
        if (cmp.get('v.obj') === 'bupl__BP_Need__c') {
            relatedRec = cmp.get('c.getRelatedNeeds');
    	} else {
            relatedRec = cmp.get('c.getRelatedDrivers');
    	}
        relatedRec.setParams({
            'tableSize' : cmp.get('v.tableSize'),
    		'apId' : apId,
    	});

        relatedRec.setCallback(this, function(response){
    		if(response.getState() === 'SUCCESS'){
                var resultData = JSON.parse(response.getReturnValue());
                console.log('resultData 2: ' + resultData);
            	cmp.set('v.data', resultData);
            }
        });
        $A.enqueueAction(relatedRec);
	}
});