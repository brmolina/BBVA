({
    doInit: function (cmp, event, helper) {    
        helper.getPageReference(cmp);
        helper.getTableData(cmp);
        
        	cmp.set('v.myColumns', [
                { label: 'Client Group', fieldName: 'urlAccount', type: 'url', typeAttributes: { label: { fieldName: 'accountName' } }, sortable: true },
                { label: 'Year', fieldName: 'year', type: 'Text', sortable: true },
                { label: 'Operation Type', fieldName: 'operation', type: 'Text', sortable: true },
                { label: 'BBVA Repayment', fieldName: 'bbvaRepayment', type: 'currency', sortable: true },
                { label: 'Total Repayment', fieldName: 'totalRepayment', type: 'currency', sortable: true },
                { label: 'Pending Balance', fieldName: 'pending', type: 'currency', sortable: true },
                { label: 'Commissions', fieldName: 'commissions', type: 'currency', sortable: true },
                { label: 'Interests', fieldName: 'interests', type: 'currency', sortable: true },
                { label: 'Average Funding Costs', fieldName: 'averageCost', type: 'currency', sortable: true }
            ]);    
    },
    updateColumnSorting: function (cmp, event, helper) {
        const fieldName = event.getParam('fieldName');
        const sortDirection = event.getParam('sortDirection');
        // Assign the latest attribute with the sorted column fieldName and sorted direction
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    },
    onClickButtonAcc: function (cmp, evt, helper) {
        helper.navToAccount(cmp, evt, helper);
    },
    onClickButtonFamily: function (cmp, evt, helper) {
        helper.navToFamily(cmp, evt, helper);
    },
    handleOperationSelected: function (cmp, event, helper) {
        const operationSelected = event.getParam('value');
        cmp.set('v.operation', operationSelected);
        helper.getTableData(cmp);
    }
})