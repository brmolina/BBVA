({
	getTableData: function (cmp) {
		var accountId = cmp.get('v.idAcc');
        var relatedOpps = cmp.get('c.getRelatedOpportunities');

        relatedOpps.setParams({
    		'accId' : accountId
    	});

        relatedOpps.setCallback(this, function(response){
    		if(response.getState() === 'SUCCESS'){
                var resultData = JSON.parse(response.getReturnValue());
            	cmp.set('v.data', resultData);
            }
        });
        $A.enqueueAction(relatedOpps);
	},
	navigateGoBackAccount : function(cmp, event, helper) {
        baseFichaGrupo.navigateGoBackAccount(cmp);
    },
    navigateGoBackBefore : function(cmp, event, helper) {
        var evt = $A.get('e.force:navigateToComponent');
        evt.setParams({
            componentDef : 'c:Salesforce1QuickAction',
            componentAttributes: {
                recordId: cmp.get('v.idAcc')
            }
        });
        evt.fire();
    }
})