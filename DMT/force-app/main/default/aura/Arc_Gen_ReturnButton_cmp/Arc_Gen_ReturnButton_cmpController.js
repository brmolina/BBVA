({
  init: function(cmp, evt, helper) {
    let promise = helper.initDelegation(cmp, evt, helper);
    promise.then(function() {
      cmp.set('v.spinnerStatus', false);
    });
  },
  closeModal: function(cmp, evt, helper) {
    helper.closeModal(cmp);
  },
  returnArce: function(cmp, evt, helper) {
    cmp.set('v.statusBtn', true);
    cmp.set('v.spinnerStatus', true);
    var reason = cmp.find('reasonInput').get('v.value');
    let promise = helper.initIdentification(cmp, evt, helper);
    promise.then($A.getCallback(function() {
      if (reason !== undefined && reason !== '') {
        helper.evaluateIdentification(cmp, evt, helper, reason);
      } else {
        helper.showToast('error', $A.get('{!$Label.c.Lc_arce_ReturnNoEmptyReason}'));
      }
    }));
  }
});