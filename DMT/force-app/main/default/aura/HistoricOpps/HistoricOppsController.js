({
  doInit : function(cmp, event, helper){
    helper.getTableData(cmp);
		cmp.set('v.columns', [
      {label: 'Opportunity Name', fieldName: 'oppUrl', type: 'url', typeAttributes: { label: { fieldName: 'oppName' }} },
      {label: 'Information Disclosure', fieldName: 'disclosure', type: 'String'},
      {label: 'Pot. Revenues', fieldName: 'potentialRevenue', type: 'currency', typeAttributes: { currencyCode: cmp.get('v.userISOCode') } },
      {label: 'Status', fieldName: 'status', type: 'String'},
      {label: 'Country', fieldName: 'oppCountry', type: 'String'},
      {label: 'Close Date', fieldName: 'closingDate', type: 'Date'}
    ]);
	},
	navigateToMyComponent : function(component, event, helper) {
    var evt = $A.get("e.force:navigateToComponent");
    evt.setParams({
      componentDef : "c:HistoricOpps",
      componentAttributes: {
	      recordId : component.get("v.recordId"),
        detailForm : 'true',
        tableSize : null,
        breadcrumbsActive: true
	    }
    });
    evt.fire();
  },
  onClickButtonAcc: function(cmp, evt, helper) {
    helper.navigateGoBackAccount(cmp, evt, helper);
  }
});