({
  onInit: function(component, event, helper) {
    // Get the empApi component
    const empApi = component.find('empApi');

    // Uncomment below line to enable debug logging (optional)
    empApi.setDebugFlag(true);

    // Register error listener and pass in the error handler function
    empApi.onError($A.getCallback(error => {
      // Error can be any type of error (subscribe, unsubscribe...)
      console.error('EMP API error: ', error);
    }));
    helper.getPersistanceStatus(component, event, helper);
  },
  handleRetry: function(component, event, helper) {
    component.set('v.spinnerStatus', true);
    helper.recallSyncService(component)
      .then(function(result) {
        helper.showToast($A.get('$Label.c.Lc_arce_Persistance_ToastTitle'), 'SUCCESS', $A.get('$Label.c.Lc_arce_Persistance_ToastInitMsgOK'), 5000);
        component.set('v.showModal', false);
        $A.get('e.force:closeQuickAction').fire();
        helper.callbackSuscribe(component, event, helper);
      })
      .catch(function(error) {
        helper.setModalErrorMessages(component, $A.get('$Label.c.Lc_arce_Persistance_ToastInitMsgKO'), $A.get('$Label.c.Lc_arce_Persistance_ErrorMessage'), error);
      });
  },
  closeModal: function(component) {
    component.set('v.showModal', false);
  }
});