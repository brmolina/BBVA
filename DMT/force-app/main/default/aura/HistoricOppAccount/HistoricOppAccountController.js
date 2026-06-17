({
  doInit: function(cmp, event, helpr) {
    cmp.set('v.accountId',cmp.get("v.pageReference").state.c__accountId);
    cmp.set('v.oppId',cmp.get("v.pageReference").state.c__oppId);
    helpr.initCmp(cmp, helpr);
  },
  reInit: function(cmp, event, helper) {
    $A.get('e.force:refreshView').fire();
  }
});