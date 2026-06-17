({
  doInit: function(cmp, event, helpr) {
    cmp.set('v.accountId',cmp.get("v.pageReference").state.c__accountId);
    cmp.set('v.visitId',cmp.get("v.pageReference").state.c__visitId);
    helpr.initCmp(cmp, helpr);
  },
  reInit: function(cmp, event, helper) {
    $A.get('e.force:refreshView').fire();
  }
});