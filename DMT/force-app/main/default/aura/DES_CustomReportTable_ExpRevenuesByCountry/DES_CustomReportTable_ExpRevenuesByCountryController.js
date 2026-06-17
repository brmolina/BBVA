({
	doInit: function (cmp, event, helper) {
		//alert('v.1.08.06');
		helper.getUserISOCode(cmp);
		cmp.set('v.myColumns', [
            	{label: 'Opportunity', fieldName: 'urlOpp', type: 'url', typeAttributes: { label: { fieldName: 'oppName' } }, sortable: true},
            	{label: 'Account', fieldName: 'urlAccount', type: 'url', typeAttributes: { label: { fieldName: 'accountName' } }, sortable: true},
				{label: 'Opportunity Country', fieldName: 'country', type: 'Text', sortable: true},
				{label: 'Expected Revenues', fieldName: 'expRevenueByCountry', type: 'currency', typeAttributes: { currencyCode: cmp.get("v.userISOCode") }, sortable: true},
            	{label: 'Created Date', fieldName: 'createdDate', type: 'date', sortable: true},
            	{label: 'Close Date', fieldName: 'closeDate', type: 'date', sortable: true},
            	{label: 'Stage Name', fieldName: 'stageName', type: 'String', sortable: true}
			]);
		helper.getTableData(cmp);
	},
    updateColumnSorting: function (cmp, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        // Assign the latest attribute with the sorted column fieldName and sorted direction
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    }
})