({
	doInit : function(cmp, event, helper) {

        helper.getTableData(cmp);
        cmp.set('v.columns', [
            {label: 'Opportunity Name', fieldName: 'oppUrl', type: 'url', typeAttributes: { label: { fieldName: 'oppName' }} },
            {label: 'Client Name', fieldName: 'accUrl', type: 'url', typeAttributes: { label: { fieldName: 'accName' } }},
            {label: 'Status', fieldName: 'status', type: 'String'},
            {label: 'Country', fieldName: 'oppCountry', type: 'String'},
            {label: 'Est. Closing Date', fieldName: 'closingDate', type: 'Date'},
            {label: 'Exp. Revenues', fieldName: 'expectedRevenue', type: 'currency', typeAttributes: { currencyCode: cmp.get('v.userISOCode') } }
        ]);

	},

	navigateToMyComponent : function(component, event, helper) {
        var evt = $A.get('e.force:navigateToComponent');
        evt.setParams({
            componentDef : 'c:RelatedAccAllOppInProgress',
            componentAttributes: {
	            idAcc : component.get('v.recordId')
	        }
        });
        evt.fire();
    }

})