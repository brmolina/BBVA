({
    doInit: function (cmp, event, helper) {
        helper.getTableData(cmp);
        cmp.set('v.myColumns', [

            { label: 'Opportunity', fieldName: 'urlOpp', type: 'url', typeAttributes: { label: { fieldName: 'oppName' } }, sortable: true },
            { label: 'Exp. Revenues', fieldName: 'expRevenue', type: 'currency', sortable: true },
            { label: 'Pot. Revenues', fieldName: 'potRevenue', type: 'currency', sortable: true },
            { label: 'Exp. Probability', fieldName: 'expProb', type: 'text', sortable: true },
            { label: 'Product Name', fieldName: 'prodName', type: 'Text', sortable: true },
            { label: 'Product Family', fieldName: 'prodFamily', type: 'Text', sortable: true },
            { label: 'Estimated Closing Date', fieldName: 'closeDate', type: 'Date', sortable: true },
            { label: 'Booking Geography', fieldName: 'countryBooking', type: 'Text', sortable: true },
            { label: 'Owner', fieldName: 'owner', type: 'Text', sortable: true }
        ]);
    },
    updateColumnSorting: function (cmp, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        // Assign the latest attribute with the sorted column fieldName and sorted direction
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    },
    onClickButtonAcc: function (cmp, evt, helper) {
        helper.goBackToAccount(cmp, evt, helper);
    },
    onClickButtonFamily: function (cmp, evt, helper) {
        helper.goBackToFamily(cmp, evt, helper);
    }
})