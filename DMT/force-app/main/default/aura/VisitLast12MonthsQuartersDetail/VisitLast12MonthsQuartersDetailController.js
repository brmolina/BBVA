({
  doInit: function (cmp, event, helper){

    helper.getTableData(cmp);
    //console.log('>>>>> v.userISOCode: ' + cmp.get("v.userISOCode"));
    //OPPORTUNITY URL   -   ACCOUNT URL     -   PRODUCT FAMILY  -   EXPECTED REVENUES   -   CREATED DATE    -   CLOSED DATE     -   STAGE NAME
    cmp.set('v.myColumns', [
        {label: 'Visit', fieldName: 'visitId', type: 'url', typeAttributes: { label: { fieldName: 'visitName' } }, sortable: true},
        {label: 'Account', fieldName: 'accountId', type: 'url', typeAttributes: { label: { fieldName: 'accountName' } }, sortable: true},
              {label: 'Start Date', fieldName: 'startDate', type: 'date', sortable: true},
              {label: 'Country', fieldName: 'country', type: 'Text', sortable: true},
              {label: 'Region', fieldName: 'region', type: 'Text', sortable: true}/*,
        //{label: 'Opportunity Product', fieldName: 'urlProduct', type: 'url', typeAttributes: { label: { fieldName: 'prodName' } }, sortable: true},
        {label: 'Product Family', fieldName: 'prodFam', type: 'Text', sortable: true},
              {label: 'Product', fieldName: 'prodName', type: 'Text', sortable: true},
        {label: 'Expected Revenues', fieldName: 'expRevenue', type: 'currency', typeAttributes: { currencyCode: cmp.get("v.userISOCode") }, sortable: true},
              {label: 'Expected Probability', fieldName: 'expectedProbability', type: 'Text', sortable: true},
        {label: 'Created Date', fieldName: 'createdDate', type: 'date', sortable: true},
        {label: 'Close Date', fieldName: 'closeDate', type: 'date', sortable: true},
        {label: 'Stage Name', fieldName: 'stageName', type: 'Text', sortable: true}*/
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
  goMobile: function(cmp, evt, helper) {
      helper.backMobile(cmp, evt, helper);
  }
})