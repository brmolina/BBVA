({
  initializeComponent: function(cmp, evt, helper) {
    let promise = helper.validateRating(cmp, evt, helper);
    return promise.then(function() {
      return helper.initDelegation(cmp, evt, helper);
    });
  },
  validateRating: function(cmp, evt, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      cmp.set('v.show', true);
      let inputAttributes = cmp.get('v.inputAttributes');
      var action = cmp.get('c.validateRatingInPreparation');
      action.setParams({
        accHasAnalysisId: inputAttributes.recordId
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var res = response.getReturnValue();
          if (res === true) {
            resolve();
          } else {
            helper.executeError(cmp, evt, helper, $A.get('$Label.c.Arc_Gen_ProposePrepRatingError') + res);
            reject();
          }
        } else {
          helper.executeError(cmp, evt, helper, response.getError()[0].message);
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  initDelegation: function(cmp3, evt, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var inputAttributes = cmp3.get('v.inputAttributes');
      var action = cmp3.get('c.initDelegation');
      action.setParams({
        accHasAnalysisId: inputAttributes.recordId
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var resp = JSON.parse(response.getReturnValue());
          if (resp.codStatus === 200) {
            cmp3.set('v.delegationWrapper', response.getReturnValue());
            cmp3.set('v.listAmbits', resp.lstAmbits);
            resolve();
          } else if (resp.codStatus === 500) {
            helper.executeError(cmp3, evt, helper, resp.msgInfo);
            reject();
          }
        } else {
          cmp3.set('v.saveDisabled', true);
          helper.executeError(cmp3, evt, helper, response.getError()[0].message);
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  evaluateDelegation: function(cmp, evt, helper) {
    var inputAttributes = cmp.get('v.inputAttributes');
    var action = cmp.get('c.evaluateDelegation');
    action.setParams({
      wrapper: cmp.get('v.delegationWrapper'),
      accHasAnalysisId: inputAttributes.recordId
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var res = JSON.parse(response.getReturnValue());
        if (res.codStatus === 200) {
          cmp.set('v.spinnerStatus', false);
        } else if (res.codStatus === 201) {
          if (res.msgInfo !== '') {
            helper.showToast('success', res.msgInfo);
          }
          helper.cancelAction(cmp);
        } else if (res.codStatus === 500) {
          cmp.set('v.saveDisabled', true);
          helper.executeError(cmp, evt, helper, res.msgInfo);
        }
      } else {
        helper.executeError(cmp, evt, helper, response.getError()[0].message);
        cmp.set('v.saveDisabled', true);
      }
    });
    $A.enqueueAction(action);
  },
  btnSaveAction: function(cmp, evt, helper) {
    var inputAttributes = cmp.get('v.inputAttributes');
    var action = cmp.get('c.saveAction');
    action.setParams({
      wrapper: cmp.get('v.delegationWrapper'),
      accHasAnalysisId: inputAttributes.recordId,
      ambit: cmp.get('v.ambit')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = JSON.parse(response.getReturnValue());
        if (resp.codStatus === 200 || resp.codStatus === 201) {
          if (resp.msgInfo !== '') {
            helper.showToast('success', resp.msgInfo);
          }
          helper.refreshTab(cmp, evt, helper);
          helper.cancelAction(cmp);
          window.location.reload();
        } else {
          helper.executeError(cmp, evt, helper, resp.msgInfo);
        }
      } else {
        helper.executeError(cmp, evt, helper, response.getError()[0].message);
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
  cancelAction: function(cmp) {
    cmp.destroy();
  },
  executeError: function(cmp, evt, helper, msgError) {
    helper.showToast('error', msgError);
    helper.cancelAction(cmp);
  },
  refreshTab: function(component, event, helper) {
    let refreshEvt = $A.get('e.c:Arc_Gen_QVCDRefresh_evt');
    refreshEvt.fire();
  },
  persistArceAction: function(cmp, evt, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var inputAttributes = cmp.get('v.inputAttributes');
      var action = cmp.get('c.persistArceAction');
      action.setParams({
        wrapper: cmp.get('v.delegationWrapper'),
        accHasAnalysisId: inputAttributes.recordId
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var resp = JSON.parse(response.getReturnValue());
          if (resp.codStatus === 200) {
            resolve();
          } else {
            reject($A.get('$Label.c.Arc_Gen_ServicePersistenceError'));
          }
        } else {
          reject(response.getError()[0].message);
        }
      });
      $A.enqueueAction(action);
    }));
  }
});