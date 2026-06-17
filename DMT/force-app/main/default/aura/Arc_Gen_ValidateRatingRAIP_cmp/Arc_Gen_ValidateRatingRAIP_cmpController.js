({
  doInit: function(component, event, helper) {
    var inputAttributes = component.get('v.inputAttributes');
    component.set('v.recordId', inputAttributes.recordId);
    component.set('v.show', true);
  },
  closeModal: function(component, event, helper) {
    component.destroy();
  }
});