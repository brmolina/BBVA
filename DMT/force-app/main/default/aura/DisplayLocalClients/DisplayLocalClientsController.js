({
  doinit: function (cmp, event, helper) {
    helper.getData(cmp, helper);
    cmp.set('v.myColumns', [
      {label: 'Client Name', fieldName: 'lName', type: 'text'},
      {label: 'Local Client Code', fieldName: 'clientCode', type: 'text'},
      {label: 'Country', fieldName: 'country', type: 'text'},
      {label: 'Entity', fieldName: 'entity', type: 'text'}
    ]);
  },
  completeSelect: function (cmp, event, helper) {
    var selected = event.getParam('selectedRows')[0];
    console.log(selected.lId);
    cmp.set('v.selectedLClientId',selected.lId);
    cmp.set('v.selectedLClientName',selected.lName);
    cmp.set('v.selectedLClientCode',selected.clientCode);
    cmp.set('v.selectedLClientEntity',selected.entity);
    cmp.set('v.selectedLClientCountry',selected.country);
    cmp.set('v.selectedLClientAlpha',selected.alpha);
  }
})