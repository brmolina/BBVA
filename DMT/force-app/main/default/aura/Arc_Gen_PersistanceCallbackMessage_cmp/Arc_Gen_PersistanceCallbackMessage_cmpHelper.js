({
  callbackSuscribe: function(component, event, helper) {
    // Get the empApi component
    const empApi = component.find('empApi');
    const channel = component.get('v.channel');
    const replayId = -1;
    empApi.subscribe(channel, replayId, $A.getCallback(eventReceived => {
      // Process event (this is called each time we receive an event)
      console.log('Received event ', JSON.stringify(eventReceived));
      if (component.get('v.accHasAnalysisId') === eventReceived.data.payload.AccountHasAnalysisId__c) {
        console.log(eventReceived.data.payload.Status__c);
        if (eventReceived.data.payload.Status__c === 'ERROR' || eventReceived.data.payload.Status__c === 'WARNING') {
          component.set('v.accHasAnalysisId', eventReceived.data.payload.AccountHasAnalysisId__c);

          helper.setModalErrorMessages(component, $A.get('$Label.c.Lc_arce_Persistance_ErrorTitle'),
            $A.get('$Label.c.Lc_arce_Persistance_ErrorMessage'), $A.get('$Label.c.Lc_arce_Persistance_ErrorSecondMessage'));
        } else if (eventReceived.data.payload.Status__c === 'OK') {
          helper.showToast($A.get('$Label.c.Lc_arce_Persistance_ToastTitle'), 'SUCCESS', $A.get('$Label.c.Lc_arce_Persistance_ToastMsgOK'), 5000);
          setTimeout($A.getCallback(function() {
            window.location.reload();
          }), 300);
        }
        helper.unsubscribe(component);
      }
    }))
      .then(subscription => {
        component.set('v.subscription', subscription);
      });
  },
  unsubscribe: function(component) {
    const empApi = component.find('empApi');
    const subscription = component.get('v.subscription');
    empApi.unsubscribe(subscription, $A.getCallback(unsubscribed => {
      component.set('v.subscription', null);
    }));
  },
  getPersistanceStatus: function(component, event, helper) {
    var action = component.get('c.getAccHasAnalysis');
    var ahaId = component.get('v.accHasAnalysisId');
    action.setParams({
      'accHasAnalysisId': ahaId
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      var resp = response.getReturnValue();
      if (state === 'SUCCESS') {
        var persistanceStatus = resp[0].arce__persistance_callback_status_type__c;
        var participantType = resp[0].arce__group_asset_header_type__c;
        if (persistanceStatus  === '1') {
          if (participantType === '2') {
            helper.recallSyncService(component)
              .then(function(result) {
                helper.showToast($A.get('$Label.c.Lc_arce_Persistance_ToastTitle'), 'WARNING', $A.get('$Label.c.Lc_arce_Persistance_ToastWarningInfo'), 500);
                helper.callbackSuscribe(component, event, helper);
              })
              .catch(function(error) {
                helper.setModalErrorMessages(component, $A.get('$Label.c.Lc_arce_Persistance_ToastInitMsgKO'), $A.get('$Label.c.Lc_arce_Persistance_ErrorMessage'), error);
              });
          } else {
            helper.showToast($A.get('$Label.c.Lc_arce_Persistance_ToastTitle'), 'WARNING', $A.get('$Label.c.Lc_arce_Persistance_ToastWarningInfo'), 500);
            helper.callbackSuscribe(component, event, helper);
          }
        } else if (persistanceStatus  === '3') {
          helper.setModalErrorMessages(component, $A.get('$Label.c.Lc_arce_Persistance_ErrorTitle'),
            $A.get('$Label.c.Lc_arce_Persistance_ErrorMessage'), $A.get('$Label.c.Lc_arce_Persistance_ErrorSecondMessage'));
        }
      }
    });
    $A.enqueueAction(action);
  },
  showToast: function(title, type, message, duration) {
    var toastEventUE = $A.get('e.force:showToast');
    toastEventUE.setParams({
      'title': title,
      'type': type,
      'mode': 'sticky',
      'duration': duration,
      'message': message
    });
    toastEventUE.fire();
  },
  setModalErrorMessages: function(component, title, message, secMessage) {
    component.set('v.modalErrorTitle', title);
    component.set('v.modalErrorMessage', message);
    component.set('v.modalErrorSecondMessage', secMessage);
    component.set('v.showModal', 'true');
    component.set('v.spinnerStatus', 'false');
  },
  recallSyncService: function(component) {
    return new Promise($A.getCallback((resolve, reject) => {
      var action = component.get('c.initCallingPersistance');
      var accHasAnalysisId = component.get('v.accHasAnalysisId');
      action.setParams({
        'accHasAnalysisId': accHasAnalysisId
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        var result = response.getReturnValue();
        if (state === 'SUCCESS') {
          var serviceCode = result.serviceCode;
          if (serviceCode.startsWith('2')) {
            resolve();
          } else {
            const errorMessage = $A.get('{!$Label.c.Lc_arce_Persistance_ToastInitMsgKO}') + result.serviceMessage;
            reject(errorMessage);
          }
        } else {
          const errorMessage = $A.get('{!$Label.c.Lc_arce_Persistance_ToastInitMsgKO}') + response.getError()[0].message;
          reject(errorMessage);
        }
      });
      $A.enqueueAction(action);
    }));
  }
});