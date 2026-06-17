({
	doInit: function (cmp, event, helper) {

		helper.getUserISOCode(cmp);
		helper.getTableData(cmp);
		//OPPORTUNITY URL   -   ACCOUNT URL     -   PRODUCT FAMILY  -   EXPECTED REVENUES   -   CREATED DATE    -   CLOSED DATE     -   STAGE NAME
		cmp.set('v.myColumns', [
				{label: 'Client', fieldName: 'cliName', type: 'Text', sortable: true},
				{label: 'Product Family', fieldName: 'prodFam', type: 'Text', sortable: true},
            	{label: 'Product', fieldName: 'prodName', type: 'Text', sortable: true},
                {label: 'Country', fieldName: 'country', type: 'Text', sortable: true},
                {label: 'Region', fieldName: 'region', type: 'Text', sortable: true},
				//{label: 'Year', fieldName: 'year', type: 'Text', sortable: true},
				//{label: 'Month', fieldName: 'month', type: 'Text', sortable: true},
                {label: 'Date', fieldName: 'dateBooking', type: 'Date', sortable: true},
                {label: 'Revenues', fieldName: 'revenues', type: 'currency', sortable: true}
            	//{label: 'Revenues', fieldName: 'urlBook', type: 'url', typeAttributes: { label: { fieldName: 'revenues' } }, sortable: true}
			]);
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