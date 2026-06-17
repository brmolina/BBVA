({
  doInit : function(cmp, event, helper) {
    helper.gtTableData(cmp);
		cmp.set('v.columns', [
      {label: 'Visit Name', fieldName: 'visitUrl', type: 'url', typeAttributes: { label: { fieldName: 'visitName' }} },
      {label: 'Information Disclosure', fieldName: 'disclosure', type: 'String'},
      {label: 'Status', fieldName: 'status', type: 'String'},
      {label: 'Start Date', fieldName: 'startDate', type: 'Date'},
      {label: 'End Date', fieldName: 'endDate', type: 'Date'}
    ]);
	},
	navigateToMyComponent : function(component, event, helper) {
    var eventt = $A.get("e.force:navigateToComponent");
    eventt.setParams({
      componentDef : "c:HistoricVisit",
      componentAttributes: {
	      recordId : component.get("v.recordId"),
      	detailForm : 'true',
          tableSize : null,
          breadcrumbsActive: true
	    }
    });
    eventt.fire();
  },
  onClickButtonAcc: function(cmp, evt, helper) {
    helper.navigateGoBackAccount(cmp, evt, helper);
  }
})