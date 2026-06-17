({
  init: function(component, event, helper) {
    let action = component.get('c.getAnalysis');
    action.setParams({
      recordId: component.get('v.recordId')
    });
    action.setCallback(this, function(response) {
      if (component.isValid() && response.getState() === 'SUCCESS') {
        var analysisId = response.getReturnValue();
        var pageReference = {
          type: 'standard__component',
          attributes: {
            componentName: 'c__Arc_Gen_UtilityBarResumeTable',
          },
          state: {
            'c__entryId': analysisId
          }};
        component.set('v.pageReference', pageReference);
      } else {
        let messageWrp = $A.get('{!$Label.c.Arc_Gen_Error}');
        var toastEvent = $A.get('e.force:showToast');
        toastEvent.setParams({
          'type': 'error',
          'title': $A.get('{!$Label.c.Arc_Gen_Error}'),
          'message': messageWrp
        });
        toastEvent.fire();
      }
    });
    $A.enqueueAction(action);
  },
  handleClick: function(component, event, helper) {
    var navService = component.find('navService');
    var pageReference = component.get('v.pageReference');
    event.preventDefault();

    navService.generateUrl(pageReference).then($A.getCallback(function(url) {
      window.open('https:' + url, '_blank');
    }), $A.getCallback(function(error) {
      var toastEvent = $A.get('e.force:showToast');
      toastEvent.setParams({
        'type': 'error',
        'title': $A.get('{!$Label.c.Arc_Gen_Error}'),
        'message': error
      });
      toastEvent.fire();
    }));
  }
});