({
  doInit: function (cmp, event, helper){
    helper.getTableData(cmp);
    //OPPORTUNITY URL   -   ACCOUNT URL     -   PRODUCT FAMILY  -   EXPECTED REVENUES   -   CREATED DATE    -   CLOSED DATE     -   STAGE NAME
    cmp.set('v.myColumns', [
        {label: 'Visit', fieldName: 'visitId', type: 'url', typeAttributes: { label: { fieldName: 'visitName' } }, sortable: true},
        {label: 'Account', fieldName: 'accountId', type: 'url', typeAttributes: { label: { fieldName: 'accountName' } }, sortable: true},
              {label: 'Start Date', fieldName: 'startDate', type: 'date', sortable: true},
              {label: 'Country', fieldName: 'country', type: 'Text', sortable: true},
              {label: 'Region', fieldName: 'region', type: 'Text', sortable: true}
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
  onClickBefore: function(cmp, evt, helper) {
      helper.navigateGoBackBefore(cmp, evt, helper);
  }
})