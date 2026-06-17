({
  init: function(component, event, helper) {
    helper.hinit(component, event);
  },
  update: function(component, event, helper) {
    component.destroy();
  },
  handleEvent: function(cmp, event) {
    var permission = event.getParam('permission');
    if (cmp.get('v.permissionEdit') === false) {
      cmp.set('v.readRecords', cmp.get('v.permissionEdit'));
    } else {
      cmp.set('v.readRecords', permission);
    }
  },
  refreshComponent: function(component, event, helper) {
    $A.get('e.force:refreshView').fire();
  }
});