({
  getUrlConfig: function(component, helper) {
    return new Promise($A.getCallback((resolve, reject) => {
      var inputAttributes = component.get('v.inputAttributes');
      var action = component.get('c.configLocalUrlOrg');
      action.setParams({
        'recordId': inputAttributes.recordId
      });
      action.setCallback(this, function(response) {
        var resp = response.getReturnValue();
        var state = response.getState();
        if (state === 'SUCCESS') {
          component.set('v.globalCustomerId', resp.accWrapper.globalId);
          component.set('v.orgURL', resp.runWayURLConfig.orgURL);
          component.set('v.vfURL', resp.runWayURLConfig.vfURL);
          resolve();
        } else {
          reject(helper.setErrorMsg(response.getError()));
        }
      });
      $A.enqueueAction(action);
    }));
  },

  handleRedirect: function(component, helper) {
    return new Promise($A.getCallback((resolve, reject) => {
      var inputAttributes = component.get('v.inputAttributes');
      var action = component.get('c.handleRedirect');
      action.setParams({
        'recordId': inputAttributes.recordId
      });
      action.setCallback(this, function(response) {
        var resp = response.getReturnValue();
        var state = response.getState();
        if (state === 'SUCCESS' && resp) {
          resolve();
        } else {
          reject(helper.setErrorMsg(response.getError()));
        }
      });
      $A.enqueueAction(action);
    }));
  },

  setErrorMsg: function(errors) {
    return (errors[0] && errors[0].message) ? errors[0].message : $A.get('{!$Label.c.Cls_arce_GRP_procError}');
  },

  setError: function(component, errors) {
    component.set('v.errorMsg', true);
    component.set('v.spinnerStatus', false);
    component.set('v.messageError', errors);
  }
});