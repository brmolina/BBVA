({
  doInit: function(component, event, helper) {
    helper.getRatingData(component, event, helper);
  },

  handleClose: function(component, event, helper) {
    helper.closeModal(component);
  },

  handleSave: function(component, event, helper) {
    component.set('v.isLoading', true);
    helper.finalizeRating(component, event, helper);
  }
});