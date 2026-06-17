({
  init: function(component, event, helper) {
    var action = component.get('c.getRAIPData');
    var analysisId = '';
    var pathArray = window.location.href.split('/');
    for (let aux = 0; aux < pathArray.length; aux++) {
      if (pathArray[aux] === 'arce__Analysis__c') {
        analysisId = pathArray[aux + 1];
      }
    }
    action.setParams({
      analysisId: analysisId
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      var resp = JSON.parse(response.getReturnValue());
      if (state === 'SUCCESS') {
        const serviceResponse = JSON.parse(resp.serviceMessage);
        component.set('v.analysisId', serviceResponse.analysisId);
        component.set('v.accHasAnalysisId', serviceResponse.accHasAnalysisId);
        component.set('v.customerId', serviceResponse.customerId);
        component.set('v.showTable', 'true');
      }
    });
    $A.enqueueAction(action);

  },
  Cancel: function(component, event, helper) {
    component.set('v.show', false);
  },
  handleWizardEvent: function(component, event, helper) { 
    var eventType = event.getParam('eventType');
    var parameters = event.getParam('parameters');

    switch (eventType) {
      case 'nextEnable':
        component.set('v.nextDisabled', !parameters.enabled);
        break;
      case 'setLoading':
        component.set('v.loading', parameters.loading);
        break;
      case 'redirectToArce':
        // Intercept redirect to ARCE event to show toast.
        var toastEvent = $A.get('e.force:showToast');
        toastEvent.setParams({
          'title': $A.get('$Label.c.Arc_Gen_FFSSUpdatedTitle'),
          'message': $A.get('$Label.c.Arc_Gen_FFSSUpdatedMessage'),
          'type': 'success',
          'duration': 3000
        });
        toastEvent.fire();

        // Fire refresh events.
        $A.get('e.force:refreshView').fire();
        $A.get('e.c:Arc_Gen_ReloadTabset_evt').fire();
        break;
    }
  },
  handleNext: function(component, event, helper) {
    // Propagate next event into wizard component.
    const raipWizard = component.find('raip-wizard');
    raipWizard.onNext();
  }
});