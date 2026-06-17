({
  initDelegation: function(cmp, evt, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var inputAttributes = cmp.get('v.inputAttributes');
      var action = cmp.get('c.initDelegation');
      action.setParams({
        accHasAnalysisId: inputAttributes.recordId
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var resp = JSON.parse(response.getReturnValue());
          if (resp.codStatus === 200) {
            cmp.set('v.delegationWrapper', response.getReturnValue());
            cmp.set('v.listAmbits', resp.lstAmbits);
            if (resp.msgInfo !== '') {
              helper.showToast('success', resp.msgInfo);
            }
            resolve();
          } else if (resp.codStatus === 500) {
            helper.errorExecute(cmp, evt, helper, resp.msgInfo, false);
            reject();
          }
        } else {
          helper.errorExecute(cmp, evt, helper, response.getError()[0].message, true);
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  initIdentification: function(cmp4, evt, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var action = cmp4.get('c.initIdentification');
      action.setParams({
        wrapper: cmp4.get('v.delegationWrapper')
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var resp = response.getReturnValue();
          cmp4.set('v.userId', resp);
          resolve();
        } else {
          helper.errorExecute(cmp4, evt, helper, response.getError()[0].message, true);
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  evaluateIdentification: function(cmp, evt, helper, reason) {
    var inputAttributes = cmp.get('v.inputAttributes');
    var action = cmp.get('c.evaluateIdentification');
    action.setParams({
      accHasAnalysisId: inputAttributes.recordId,
      wrapper: cmp.get('v.delegationWrapper'),
      userId: cmp.get('v.userId'),
      reason: reason
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = JSON.parse(response.getReturnValue());
        if (resp.codStatus === 200) {
          cmp.set('v.spinnerStatus', false);
          if (resp.msgInfo !== '') {
            helper.showToast('success', resp.msgInfo);
          }
          helper.refreshTab(cmp, evt, helper);
          helper.closeModal(cmp);
        } else if (resp.codStatus === 500) {
          helper.errorExecute(cmp, evt, helper, resp.msgInfo, false);
        }
      } else {
        helper.errorExecute(cmp, evt, helper, response.getError()[0].message, true);
      }
    });
    $A.enqueueAction(action);
  },
  showToast: function(type, message) {
    var toastEventUE = $A.get('e.force:showToast');
    toastEventUE.setParams({
      'title': '',
      'type': type,
      'mode': 'sticky',
      'duration': '8000',
      'message': message
    });
    toastEventUE.fire();
  },
  closeModal: function(cmp) {
    cmp.destroy();
  },
  errorExecute: function(cmp, evt, helper, msgInfo, refresh) {
    if (msgInfo !== '') {
      helper.showToast('error', msgInfo);
    }
    if (refresh) {
      helper.refreshTab(cmp, evt, helper);
    }
    helper.closeModal(cmp);
  },
  refreshTab: function(cmp, evt, helper) {
    window.setTimeout($A.getCallback(function() {
      window.location.reload();
    }), 2500);
  }
});