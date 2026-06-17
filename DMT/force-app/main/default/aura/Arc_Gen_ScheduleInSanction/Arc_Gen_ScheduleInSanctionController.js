({
  init: function(component, event, helper) {
    let promise = helper.initDelegation(component, event, helper);
    promise.then(function() {
      component.set('v.spinnerStatus', false);
    });
  },
  cancel: function(component, event, helper) {
    helper.cancelAction(component);
  },
  save: function(component, event, helper) {
    helper.updateCommittee(component, event, helper);
  },
  onSelectCom: function(component, event, helper) {
    helper.getCommitteeLabel(component, event);
    component.set('v.committeeValue', event.getParam('value'));
    component.set('v.buttonDisabled', false);
  }
});