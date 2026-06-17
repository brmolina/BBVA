({
  callPersistOverlay: function(component8, event) {
    return new Promise($A.getCallback(function(res, rej) {
      var action = component8.get('c.callPersistModifiers');
      action.setParams({
        aHasAnalysId: component8.get('v.recordId'),
        methodType: 'persistenceOverlays'
      });
      component8.set('v.isLoading', true);
      action.setCallback(this, function(response) {
        var state = response.getState();
        var resp = response.getReturnValue();
        if (state === 'SUCCESS' && (resp.serviceCode === '200' || resp.serviceCode === '201' || resp.serviceCode === '204')) {
          res();
        } else {
          var info = response.getReturnValue();
          component8.set('v.formIncompleteInfo', info);
          rej();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  callOverlayRating: function(component9) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var action = component9.get('c.callOverlayRating');
      action.setParams({
        aHasAnalysId: component9.get('v.recordId')
      });

      action.setCallback(this, function(response) {
        var resp = response.getReturnValue();
        var state = response.getState();

        if (state === 'SUCCESS') {
          if (resp.serviceCode === '200' && resp.saveStatus === 'true') {
            resolve();
          } else if (resp.serviceCode !== '200') {
            var errorWrapper = JSON.parse(resp.serviceMessage);
            component9.set('v.errorCode', $A.get('{!$Label.arce.Arc_Gen_RatingError_ErrorCode}') + ' ' + errorWrapper.errorCode);
            component9.set('v.errorTitle', errorWrapper.errorTitle);
            component9.set('v.message', errorWrapper.errorMessage);
            reject();
          }
          if (resp.saveStatus === 'false') {
            component9.set('v.message', $A.get('{!$Label.arce.Lc_arce_newAnalysisError}') + resp.saveMessage);
            reject();
          }
        } else {
          component9.set('v.message', $A.get('{!$Label.arce.Lc_arce_newAnalysisError}'));
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },

  ratingProcessOK: function(component10) {
    component10.set('v.message', $A.get('{!$Label.arce.Lc_arce_successAndCloseWindow}'));
    component10.set('v.success', 'yes');
    this.refreshRating(component10);
    component10.set('v.isLoading', 'false');
  },

  cancelAction: function(component) {
    component.set('v.success', 'no');
    component.set('v.isLoading', 'false');
  },

  fireToast: function(type, message) {
    let toastError = $A.get('e.force:showToast');
    toastError.setParams({
      'title': type + '!',
      'type': type.toLowerCase(),
      'message': message
    });
    toastError.fire();
  },

  refreshRating: function(component) {
    var tabRefresh = $A.get('e.dyfr:SaveObject_evt');
    tabRefresh.setParams({
      'recordId': component.get('v.recordId')
    });
    tabRefresh.fire();
  }
});