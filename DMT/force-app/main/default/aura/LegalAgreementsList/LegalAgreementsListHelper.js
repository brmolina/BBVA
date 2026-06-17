({
	getTableData: function (cmp) {
		var accountId = cmp.get('v.recordId');
        var tableSizeP = cmp.get('v.tableSize');
        var relatedMarcos = cmp.get('c.relateContratos');
        relatedMarcos.setParams({
            "tableSize" : tableSizeP,
    		"accId" : accountId
    	});

        relatedMarcos.setCallback(this, function(response){
    		if(response.getState() === "SUCCESS"){
                var resultData = JSON.parse(response.getReturnValue());
            	cmp.set("v.data", resultData);
            }
        });
        $A.enqueueAction(relatedMarcos);
	}
})