({
  doInit : function(component, event, helper) {
    helper.getAccountFromURL(component, helper);
    helper.getAccountInfo(component, helper);
    component.set('v.conditionWrp',null);
  }
})