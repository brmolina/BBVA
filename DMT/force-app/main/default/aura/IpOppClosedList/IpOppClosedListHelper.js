({
	getTableData: function (cmp) {
        var tableSizeP = cmp.get('v.tableSize');
        var relatedMarcos = cmp.get('c.relateOpportunities');
        relatedMarcos.setParams({
            "tableSize" : tableSizeP,
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