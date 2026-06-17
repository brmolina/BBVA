({
  init: function(cmp, evt, helper) {
    let promise = helper.initializeComponent(cmp, evt, helper);
    promise.then(function(resolve) {
      helper.evaluateDelegation(cmp, evt, helper);
    });
  },
  cancelAction: function(cmp, evt, helper) {
    helper.cancelAction(cmp, evt, helper);
  },
  setAmbitValue: function(cmp, evt, helper) {
    cmp.set('v.ambit', evt.getParam('value'));
    cmp.set('v.saveDisabled', false);
  },
  btnSaveAction: function(cmp, evt, helper) {
    cmp.set('v.spinnerStatus', true);
    cmp.set('v.cancelDisabled', true);
    cmp.set('v.saveDisabled', true);
    helper.persistArceAction(cmp, evt, helper)
      .then($A.getCallback(function(resolve) {
        helper.btnSaveAction(cmp, evt, helper);
      }))
      .catch($A.getCallback(function(err) {
        helper.executeError(cmp, evt, helper, err);
      }));
  }
});