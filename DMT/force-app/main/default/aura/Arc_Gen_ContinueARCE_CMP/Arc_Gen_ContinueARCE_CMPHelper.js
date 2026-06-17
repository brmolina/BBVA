({
  init: function(component, event, helper) {
    component.set('v.loading', true);
    var actionCall = component.get('c.getGroupId');
    actionCall.setParams({
      recordId: component.get('v.recordId')
    });
    actionCall.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = response.getReturnValue();

        component.set('v.arceData', resp);

        if (resp.arce__is_RTC__c === false) {
          component.set('v.arceTypeToContinue', resp.arce__anlys_wkfl_sub_process_type__c === '4' ? 'raip' : 'analysis');
          helper.initHandler(component, event, helper);
        } else {
          component.set('v.loading', false);
          component.set('v.rollbackStatus', 'IN_PROGRESS');
          helper.rollbackHandler(component, event, helper);
        }
      } else if (state === 'ERROR') {
        helper.showToast('error', 'There was an error(ContinueARCE-getGroupId): ' + response.getError()[0].message);
        component.set('v.loading', false);
      }
    });
    $A.enqueueAction(actionCall);
  },
  initHandler: function(component, event, helper) {
    var actionCall = component.get('c.getAccOrLocalClientId');
    actionCall.setParams({
      analysisId: component.get('v.recordId')
    });
    actionCall.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = response.getReturnValue();
        component.set('v.idGroup', resp);
        component.set('v.loading', false);
      } else if (state === 'ERROR') {
        helper.showToast('error', 'There was an error(ContinueARCE-getAccOrLocalClientId): ' + response.getError()[0].message);
      }
    });
    $A.enqueueAction(actionCall);
  },
  rollbackHandler: function(component, event, helper) {
    var actionCall = component.get('c.rollback2021RTC');
    actionCall.setParams({
      analysisId: component.get('v.recordId')
    });
    actionCall.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        component.set('v.rollbackStatus', 'OK');
        setTimeout($A.getCallback(function() {
          window.location.href = '/'  + component.get('v.arceData.arce__Group__c');
        }), 3000);
      } else {
        component.set('v.rollbackStatus', 'ERROR');
        component.set('v.rollbackError', JSON.parse(response.getError()[0].message));
      }
    });
    $A.enqueueAction(actionCall);
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
  }
});