({
  doInit: function(component, event, helper) {
    var action = component.get('c.getOverlaySupport');
    action.setParams({
      'ahaId': component.get('v.recordId')
    });
    action.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        component.set('v.overlaySupport', response.getReturnValue());
      }
    });
    $A.enqueueAction(action);
  }
});