({
  doInit: function(component, event, helper) {
    helper.initDelegation(component, event, helper);
  },

  handleChange: function(component, event, helper) {
    if (!component.get('v.isReason')) {
      component.set('v.isReason', true);
    }
  },

  handleClose: function(component, event, helper) {
    helper.closeModal(component);
  },

  handleSave: function(component, event, helper) {
    component.set('v.isLoading', true);
    component.set('v.disabledButtons', true);

    helper.returnRating(component, event, helper);
  }
});