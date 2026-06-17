({
	doInit: function (cmp, event, helper) {
		helper.getTableData(cmp);
        cmp.set('v.myColumns', [
            { label: 'Visit Name', fieldName: 'visName', type: 'Text', sortable: true },
            { label: 'Client Name', fieldName: 'accName', type: 'Text', sortable: true },
            { label: 'Start Date', fieldName: 'alertName', type: 'Text', sortable: true },
            { label: 'Visit Owner', fieldName: 'ownerName', type: 'Text', sortable: true },
            { label: 'Involved Areas', fieldName: 'areas', type: 'Text', sortable: true },
            { label: 'Country', fieldName: 'country', type: 'Text', sortable: true }
        ]);
	},
	sortingColumns: function (cmp, event, helper) {
        cmp.set("v.sortedBy", event.getParam('fieldName'));
        cmp.set("v.sortedDirection", event.getParam('sortDirection'));
        helper.sortData(cmp, event.getParam('fieldName'), event.getParam('sortDirection'));
    },
    goToAccountVisit: function (cmp, evt, helper) {
        helper.navigateGoBackAccountVisit(cmp, evt, helper);
    }
})