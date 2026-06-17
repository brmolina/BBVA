({
  doInit: function(component, event, helper) {
    helper.getTableData(component, event, helper);
  },
  refresCmp: function(component, event, helper) {
    var tabRefresh = $A.get('e.dyfr:SaveObject_evt');
    tabRefresh.setParams({
      recordId: component.get('v.recordId')
    });
    tabRefresh.fire();
  }
});