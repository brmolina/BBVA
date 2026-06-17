({
  doInit: function (cmp, event, helper){
    helper.getTableData(cmp);
    //OPPORTUNITY URL   -   ACCOUNT URL     -   PRODUCT FAMILY  -   EXPECTED REVENUES   -   CREATED DATE    -   CLOSED DATE     -   STAGE NAME
    cmp.set('v.myColumns', [
        //{label: 'Account', fieldName: 'accountId', type: 'url', typeAttributes: { label: { fieldName: 'accountName' } }, sortable: true},
                {label: 'Account', fieldName: 'accountName', type: 'Text', sortable: true},
                {label: 'Country', fieldName: 'country', type: 'Text', sortable: true},
              {label: 'Region', fieldName: 'region', type: 'Text', sortable: true},
                {label: 'Family', fieldName: 'familyProd', type: 'Text', sortable: true},
                {label: 'Product', fieldName: 'product', type: 'Text', sortable: true},
                {label: 'Date', fieldName: 'dateBooking', type: 'Text', sortable: true},
                {label: 'Revenues', fieldName: 'revenues', type: 'currency', sortable: true}
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