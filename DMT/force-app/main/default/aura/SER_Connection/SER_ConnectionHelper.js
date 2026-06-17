({
  responseStatus: function(response) {
    var rspState = response.getState();
    if (rspState === 'SUCCESS') {
      console.log('OK');
    } else {
      console.log('ERROR CONNECTION');
    }
  },
  callServer: function(component, event, method, params, callback, helper) {
    var action = component.get(method);
    if (action) {
      if (params) {
        action.setParams(params);
      }
      if (callback) {
        action.setCallback(this, callback);
      } else {
        console.log('error');
      }
      $A.enqueueAction(action);
    } else {
      console.log('error');
    }
  },

  //Call functions as Promise
  helperFunctionAsPromise: function(component, event, helper, helperFunction) {
    return new Promise($A.getCallback(function(resolve) {
      helperFunction(component, event, helper, resolve);
    }));
  },

  showToastError: function(message, type) {
    var toastEvent = $A.get('e.force:showToast');
    toastEvent.setParams({
      message: message,
      type: type,
      mode: 'dismissible',
      duration: 7000
    });
    toastEvent.fire();
  },

  saveLog: function(component, event, helper, subject, recordId, remedyUser, errMsg) {
    console.log('Entro a salvar el log');
    var params = {
      'subject': subject,
      'recordId': recordId,
      'remedyUser': remedyUser,
      'errMsg': errMsg
    };
    var fncallback = function(response) {
      var state = response.getState();
      if (component.isValid() && state === 'SUCCESS') {
        console.log('saveLog: SUCCESS');
      } else if (state === 'ERROR') {
        console.log('saveLog: ERROR');
      } else {
        console.log('saveLog: Failed with state ' + state);
      }
    };
    helper.callServer(component, event, 'c.saveLog', params, fncallback, helper);
  },

  trateErrors: function(response) {
    var errors = response.getError();
    if (errors) {
      if (errors[0] && errors[0].message) {
        console.log('Error message: ' + errors[0].message);
      }
    } else {
      console.log('Unknown error');
    }
  }
});