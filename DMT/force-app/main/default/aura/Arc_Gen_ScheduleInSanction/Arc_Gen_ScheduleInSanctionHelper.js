({
  initDelegation: function(component1, helper, event) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var inputAttributes = component1.get('v.inputAttributes');
      var action = component1.get('c.initDelegation');
      action.setParams({
        accHasAnalysisId: inputAttributes.recordId
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var resp = JSON.parse(response.getReturnValue());
          if (resp.codStatus === 200) {
            component1.set('v.delegationWrapper', response.getReturnValue());
            component1.set('v.committeesList', resp.lstComittees);
            resolve();
          } else if (resp.codStatus === 500) {
            helper.executeError(component1, event, helper, response.getError()[0].message);
            reject();
          }
        } else {
          component1.set('v.disableButtons', true);
          helper.executeError(component1, event, helper, response.getError()[0].message);
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  updateCommittee: function(component, event, helper) {
    component.set('v.spinnerStatus', true);
    component.set('v.buttonDisabled', true);
    var inputAttributes = component.get('v.inputAttributes');
    var action = component.get('c.updateCommittee');
    action.setParams({
      'committeeValue': component.get('v.committeeValue'),
      'recordId': inputAttributes.recordId,
      'committeeDesc': component.get('v.committeeDesc')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        helper.showToast('success', $A.get('{!$Label.c.Arc_Gen_Record_Update_Success}'));
        helper.refreshTab(component);
        helper.cancelAction(component);
      } else {
        helper.executeError(component, event, helper, response.getError()[0].message);
        component.set('v.buttonDisabled', false);
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
  refreshTab: function(component) {
    let refreshEvt = $A.get('e.c:Arc_Gen_QVCDRefresh_evt');
    refreshEvt.fire();
  },
  getCommitteeLabel: function(component, event) {
    var list = component.get('v.committeesList');
    var currentLabel =  list.filter(function(option) {
      return option.value === event.getParam('value');
    });
    component.set('v.committeeDesc', currentLabel[0].label);
  },
  cancelAction: function(component) {
    component.destroy();
  },
  executeError: function(component, event, helper, msgError) {
    helper.showToast('error', msgError);
    helper.cancelAction(component);
  }
});