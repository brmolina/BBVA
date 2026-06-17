({
  doInit: function(cmp, event, helpr) {
    cmp.set('v.oppLineId',cmp.get("v.pageReference").state.c__oppLineId);
    cmp.set('v.oppId',cmp.get("v.pageReference").state.c__oppId);
    helpr.initComponent(cmp, event, helpr);
  },
  reInit: function(cmp, event, helper) {
    $A.get('e.force:refreshView').fire();
  }
});