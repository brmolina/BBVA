({
	getTableData: function (cmp) {
		var accountId = cmp.get("v.recordId");
        var familyProd = cmp.get ("v.familyParam");
        var country = cmp.get ("v.country");
        var relatedVisits = cmp.get("c.getRelatedVisits");
        relatedVisits.setParams({
            "tableSize" : '5',
    		"accId" : accountId,
            "family": familyProd,
            "country" : country
    	});

        relatedVisits.setCallback(this, function(response){
    		if(response.getState() === "SUCCESS"){
                var resultData = JSON.parse(response.getReturnValue());
                cmp.set("v.data", resultData);
                if(resultData.length > 0) {
                    if(resultData[0].accType !== $A.get("{!$Label.c.DES_RT_Subsidiary}")) {
                        cmp.set('v.columns', [
                            {label: 'Visit Name', fieldName: 'visUrl', type: 'url', typeAttributes: { label: { fieldName: 'visName' }} },
                            {label: 'Client', fieldName: 'accUrl', type: 'url', typeAttributes: { label: { fieldName: 'accName' } }},
                            {label: 'Country', fieldName: 'country', type: 'String'},
                            {label: 'Product', fieldName: 'prod', type: 'String'},
                            {label: 'Owner', fieldName: 'creatBy', type: 'String'},
                            {label: 'Start Date', fieldName: 'startDate', type: 'Date'}
                        ]);
                    } else if(resultData[0].accType === $A.get("{!$Label.c.DES_RT_Subsidiary}")){
                        cmp.set('v.columns', [
                            {label: 'Visit Name', fieldName: 'visUrl', type: 'url', typeAttributes: { label: { fieldName: 'visName' }} },
                            {label: 'Client', fieldName: 'accUrl', type: 'url', typeAttributes: { label: { fieldName: 'accName' } }},
                            {label: 'Start Date', fieldName: 'startDate', type: 'Date'},
                            {label: 'Created By', fieldName: 'creatBy', type: 'String'}
                        ]);
                    }
                }
            }
        });
        $A.enqueueAction(relatedVisits);
	}
})