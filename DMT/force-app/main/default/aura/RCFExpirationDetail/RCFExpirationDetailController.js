({
	updateColumnSorting: function (component, event, helper) {
		var campo = event.getParam('fieldName');
		var direccion = event.getParam('sortDirection');
		component.set("v.sortedBy", campo);
		component.set("v.sortedDirection", direccion);
		helper.sortDataTable(component, campo, direccion);
	},
	doInit: function (component, event, helper) {
		helper.getTableDataCnt(component, helper);
		var label1 = 'Commitment BBVA ('+$A.get("$Locale.currencyCode")+')';
		var label2 = 'Commitment Total ('+$A.get("$Locale.currencyCode")+')';
		component.set('v.myColumns', [
			{label: 'Group', fieldName: 'urlRecord', type: 'url',  typeAttributes: { label: { fieldName: 'participant' } }, sortable: true},
			{label: 'Expiration Date', fieldName: 'expDate', type: 'date', sortable: true},
			{label: 'Financial Product', fieldName: 'productType', type: 'text', sortable: true},
			{label: label1, fieldName: 'shareAmount', type: 'text', sortable: true},
			{label: label2, fieldName: 'creditAmount', type: 'text', sortable: true}
		]);
	},
    onClickButtonAcc: function(cmp, evt, helper) {
      helper.navigateGoBackAccount(cmp, evt, helper);
    },
    onClickButtonFamily: function(cmp, evt, helper) {
      helper.navigateGoBackFamily(cmp, evt, helper);
    }
})