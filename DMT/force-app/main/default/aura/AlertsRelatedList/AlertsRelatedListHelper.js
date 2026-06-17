({
	getTableData: function (cmp) {
		var accountId = cmp.get('v.recordId');
        var familyProd = cmp.get ('v.familyParam');
        var tableSizeP = cmp.get('v.tableSize');
        var relatedAlerts = cmp.get('c.relatedAlerts');
        relatedAlerts.setParams({
            "tableSize" : tableSizeP,
    		"accId" : accountId,
            "family" : familyProd
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