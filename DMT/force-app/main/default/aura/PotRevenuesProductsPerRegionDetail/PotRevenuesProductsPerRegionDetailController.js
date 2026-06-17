({
  doInit: function (cmp, event, helper){
    helper.getTableData(cmp);
    //OPPORTUNITY URL   -   ACCOUNT URL     -   PRODUCT FAMILY  -   EXPECTED REVENUES   -   CREATED DATE    -   CLOSED DATE     -   STAGE NAME
    cmp.set('v.myColumns', [
                {label: 'Opportunity', fieldName: 'urlOpp', type: 'url', typeAttributes: { label: { fieldName: 'oppName' } }, sortable: true},
        {label: 'Account', fieldName: 'urlAccount', type: 'url', typeAttributes: { label: { fieldName: 'oppAccountName' } }, sortable: true},
        //{label: 'Opportunity Product', fieldName: 'urlProduct', type: 'url', typeAttributes: { label: { fieldName: 'prodName' } }, sortable: true},
        // {label: 'Product Family', fieldName: 'prodFam', type: 'Text', sortable: true},
        {label: 'Region Name', fieldName: 'regionName', type: 'Text', sortable: true},
              {label: 'Product', fieldName: 'prodName', type: 'Text', sortable: true},
              {label: 'Potential Revenues', fieldName: 'potRevenue', type: 'currency', typeAttributes: { currencyCode: cmp.get("v.userISOCode") }, sortable: true},
        {label: 'Expected Revenues', fieldName: 'expRevenue', type: 'currency', typeAttributes: { currencyCode: cmp.get("v.userISOCode") }, sortable: true},
        {label: 'Created Date', fieldName: 'createdDate', type: 'date', sortable: true},
        {label: 'Close Date', fieldName: 'closeDate', type: 'date', sortable: true},
        {label: 'Stage Name', fieldName: 'stageName', type: 'Text', sortable: true}
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
    onClickButtonAcc: function(cmp, evt, helper) {
      helper.navigateGoBackAccount(cmp, evt, helper);
    },
    onClickButtonFamily: function(cmp, evt, helper) {
      helper.navigateGoBackFamily(cmp, evt, helper);
    }
})