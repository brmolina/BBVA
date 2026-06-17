({
  getInfoAnalysis: function(component, helper) {
    var action = component.get('c.getInfoAnalysis');
    action.setParams({
      accHasId: component.get('v.hasRecordId')
    });
    return new Promise($A.getCallback(function(resolve, reject) {
      action.setCallback(this, function(response) {
        var resp = response.getReturnValue();
        var state = response.getState();
        if (state === 'SUCCESS') {
          component.set('v.analysisObj', resp);
          resolve();
        } else {
          reject();
        }
      });

      $A.enqueueAction(action);
    }));
  },
  executeService: function(component, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var action = component.get('c.executeService');
      action.setParams({
        confName: component.get('v.confName'),
        mapObj: component.get('v.analysisObj')
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        var resp = response.getReturnValue();
        var successCodes = component.get('v.successCodes');
        var customCode = false;
        if (state === 'SUCCESS') {
          if (successCodes !== undefined) {
            successCodes = successCodes.split(',');
            customCode = true;
          }
          if (((customCode && successCodes.includes(resp.serviceCode)) || (!customCode && resp.serviceCode === successCodes)) && resp.saveStatus === 'true') {
            resolve();
          } else {
            reject();
          }
        } else {
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  cancelAction: function(component) {
    component.set('v.success', 'no');
    component.set('v.spinner', 'false');
    component.set('v.message', $A.get('{!$Label.c.Lc_arce_NewARCE_UnexpectedError}'));
  },
  refreshTab: function(component) {
    var tabRefresh = $A.get('e.dyfr:SaveObject_evt');
    tabRefresh.setParams({
      'recordId': component.get('v.hasRecordId')
    });
    tabRefresh.fire();
  }
});