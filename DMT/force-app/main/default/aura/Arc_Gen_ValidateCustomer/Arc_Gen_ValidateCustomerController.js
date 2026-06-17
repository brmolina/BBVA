({
  init: function(component, event, helper) {
    component.set('v.show', true);
    helper.hvalidate(component, event);
  },
  close: function(component, event) {
    component.set('v.show', false);
    if (component.get('v.validation') && component.get('v.analysisType') !== 'Client') {
      $A.get('e.force:refreshView').fire();
    }
    component.set('v.validation', false);
  },
  closeError: function(component, event) {
    component.set('v.error', false);
  }
});