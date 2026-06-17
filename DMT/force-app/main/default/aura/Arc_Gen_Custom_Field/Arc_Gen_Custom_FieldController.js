({
  init: function(component, event, helper) {
    var action = component.get('c.getFieldValue');
    action.setParams({
      ahaId: component.get('v.recordId'),
      fieldName: component.get('v.fieldName'),
      objectName: component.get('v.objectName')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        component.set('v.fieldValue', response.getReturnValue());
      }
    });
    $A.enqueueAction(action);
  }
});