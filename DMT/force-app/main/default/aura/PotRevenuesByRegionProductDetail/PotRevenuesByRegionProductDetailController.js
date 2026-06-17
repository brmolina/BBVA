({
	doInit: function (cmp, event, helper) {
		helper.getUserISOCode(cmp);
		helper.getTableData(cmp);
		console.log('>>>>> v.userISOCode: ' + cmp.get('v.userISOCode'));
		cmp.set('v.myColumns', [
				{label: 'Opportunity', fieldName: 'urlOpp', type: 'url', typeAttributes: { label: { fieldName: 'oppName' } }, sortable: true},
				{label: 'Account', fieldName: 'urlAccount', type: 'url', typeAttributes: { label: { fieldName: 'oppAccountName' } }, sortable: true},
				{label: 'Product Family', fieldName: 'prodFam', type: 'Text', sortable: true},
            	{label: 'Product', fieldName: 'prodName', type: 'Text', sortable: true},
            	{label: 'Pot. Revenues', fieldName: 'potRevenue', type: 'currency', typeAttributes: { currencyCode: cmp.get('v.userISOCode') }, sortable: true},
				{label: 'Exp. Revenues', fieldName: 'expRevenue', type: 'currency', typeAttributes: { currencyCode: cmp.get('v.userISOCode') }, sortable: true},
				{label: 'Created Date', fieldName: 'createdDate', type: 'date', sortable: true},
				{label: 'Close Date', fieldName: 'closeDate', type: 'date', sortable: true},
				{label: 'Stage Name', fieldName: 'stageName', type: 'Text', sortable: true}
			]);
	},
	updateColumnSorting: function (cmp, event, helper) {
		var fieldName = event.getParam('fieldName');
		var sortDirection = event.getParam('sortDirection');
		cmp.set('v.sortedBy', fieldName);
		cmp.set('v.sortedDirection', sortDirection);
		helper.sortData(cmp, fieldName, sortDirection);
	},
	onClickButtonAcc: function(cmp, evt, helper) {
    	helper.navigateGoBackAccount(cmp, evt, helper);
  	},
  	onClickButtonBefore: function(cmp, evt, helper) {
    	helper.navigateGoBackBefore(cmp, evt, helper);
  	}
})