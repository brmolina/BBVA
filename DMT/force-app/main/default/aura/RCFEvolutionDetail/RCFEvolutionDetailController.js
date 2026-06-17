({
	doInit: function (cmp, event, helper) {
		helper.getTableData(cmp, helper);
		cmp.set('v.myColumns', [
			{label: 'Group', fieldName: 'urlAccount', type: 'url', typeAttributes: { label: { fieldName: 'accountName' } }, sortable: true},
			{label: 'Date', fieldName: 'dateEv', type: 'date', sortable: true},
			{label: 'Commitment', fieldName: 'importe', type: 'text', sortable: true},
			{label: 'Drawn BBVA', fieldName: 'saldoVivo', type: 'text', sortable: true},
			{label: '% Use', fieldName: 'usePercent', type: 'Text', sortable: true},
			{label: 'Currency', fieldName: 'currencyIso', type: 'text'}
		]);
	},
	updateColumnSorting: function (cmp, event, helper) {
		var fieldName = event.getParam('fieldName');
		var sortDirection = event.getParam('sortDirection');
		// Assign the latest attribute with the sorted column fieldName and sorted direction
		cmp.set("v.sortedBy", fieldName);
		cmp.set("v.sortedDirection", sortDirection);
		helper.sortInfo(cmp, fieldName, sortDirection);
	},
    onClickButtonAcc: function(cmp, evt, helper) {
      helper.navigateGoBackAccount(cmp, evt, helper);
    },
    onClickButtonFamily: function(cmp, evt, helper) {
      helper.navigateGoBackFamily(cmp, evt, helper);
    }
})