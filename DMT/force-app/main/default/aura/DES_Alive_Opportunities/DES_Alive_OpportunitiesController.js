({
  doInit: function (component, event, helper) {
    console.log('v 02.00');
    helper.getUserISOCode(component);
    helper.getTableData(component);
    component.set('v.myColumns', [
      { label: 'Opportunity', fieldName: 'oppUrl', type: 'url', typeAttributes: { label: { fieldName: 'oppName' } } },
      { label: 'Client', fieldName: 'clientProspectURL', type: 'url', typeAttributes: { label: { fieldName: 'clientProspect' } } },
      { label: 'Products', fieldName: 'products', type: 'String' },
      { label: 'Status', fieldName: 'status', type: 'String' },
      { label: 'Expected Revenues', fieldName: 'expectedRevenue', type: 'currency', typeAttributes: { currencyCode: component.get("v.userISOCode") } },
      { label: 'Countries Participants', fieldName: 'countriesParticipants', type: 'String' },
      { label: 'Closing Date', fieldName: 'closingDate', type: 'date' }
    ]);
  },
  navigateToMyComponent: function (component, event, helper) {
    var evt = $A.get("e.force:navigateToComponent");
    evt.setParams({
      componentDef: "c:DES_CustomReportTable_Alive_Opportunities",
      componentAttributes: {
        countriesToDisplay: component.get("v.countriesToDisplay"),
          gmRolVery: component.get('v.gmRolVery')
      }
    });
    evt.fire();
  }
})