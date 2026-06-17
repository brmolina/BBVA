({
	doInit : function(component, event, helper) {
        //alert('v 1.0.0');
        helper.getUserISOCode(component);
		helper.getTableData(component);
		component.set('v.myColumns', [
				{label: 'Opportunity', fieldName: 'oppUrl', type: 'url', typeAttributes: { label: { fieldName: 'oppName' } }},
				{label: 'Client', fieldName: 'clientURL', type: 'url', typeAttributes: { label: { fieldName: 'clientName' } }},
				{label: 'Expected Revenues', fieldName: 'expectedRevenue', type: 'currency', typeAttributes: { currencyCode: component.get("v.userISOCode") }},
				{label: 'Last Modify', fieldName: 'lastModifDate', type: 'date'}
			]);
		
	}
})