({
	doInit : function(cmp, event, helper) {
		helper.getTableData(cmp);
		cmp.set('v.columns', [
			{label: 'Opportunity Name', fieldName: 'oppUrl', type: 'url', typeAttributes: { label: { fieldName: 'cOppName' }} },
			{label: 'Information disclosure', fieldName: 'cInfDiscOpp', type: 'String'},
			{label: 'Visit Name', fieldName: 'visitUrl', type: 'url', typeAttributes: { label: { fieldName: 'cVisitName' }} },
            {label: 'Information disclosure', fieldName: 'cInfDiscVisit', type: 'String'}
        ]);
	},

	navigateToMyComponent : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:OppIpRelatedToVisitNonIpList",
            componentAttributes: {
            	detailForm : 'true',
            	tableSize : null
	        }
        });
        evt.fire();
    }

})