({
  doInit: function(component, event, helper) {
    component.set('v.showModal', true);
    helper.fetchDiscardReasons(component);
  },

  onSelectReason: function(component, event, helper) {
    helper.setupReasonLabel(component, event);
    component.set('v.reasonValue', event.getParam('value'));
    component.set('v.disableButtons', false);
  },

  handleClose: function(component, event, helper) {
    helper.closeModal(component);
  },

  handleSave: function(component, event, helper) {
    component.set('v.isLoading', true);
    helper.cancelRating(component, event, helper);
  }
});