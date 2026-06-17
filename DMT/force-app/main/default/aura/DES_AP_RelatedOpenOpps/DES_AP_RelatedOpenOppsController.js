({
  doInit: function(cmp, event, helper) {
    var locale = $A.get('$Locale.currencyCode');
    helper.gtAPAccountId(cmp);
    cmp.set('v.columns', [
      {
        label: 'Opportunity Name',
        fieldName: 'oppUrl',
        type: 'url',
        typeAttributes: { label: { fieldName: 'oppName' } }
      },
      {
        label: 'Client Name',
        fieldName: 'accUrl',
        type: 'url',
        typeAttributes: { label: { fieldName: 'accName' } }
      },
      { label: 'Status', fieldName: 'status', type: 'String' },
      { label: 'Country', fieldName: 'oppCountry', type: 'String' },
      { label: 'Est. Closing Date', fieldName: 'closingDate', type: 'Date' },
      {
        label: 'Exp. Revenues',
        fieldName: 'expectedRevenue',
        type: 'currency',
        typeAttributes: { currencyCode: locale }
      }
    ]);
  },

  navigateToMyComponent: function(component, event, helper) {
    var evt = $A.get('e.force:navigateToComponent');
    evt.setParams({
      componentDef: 'c:DES_AP_RelatedOpenOpps',
      componentAttributes: {
        accId: component.get('v.accId'),
        tableSize: null,
        recordId: component.get('v.recordId')
      }
    });
    evt.fire();
  }
});