({//eslint-disable-line
  doInit: function(component, event, helper) {
    helper.handleInit(component, event, helper);
  },
  handleChange: function(component, event, helper) {
    helper.handleChange(component, event, helper);
  },
  handleChangeAditional: function(component, event, helper) {
    helper.handleChangeAditional(component, event, helper);
  },
  closeModal: function(component, event, helper) {
    helper.closeModal(component, event, helper);
  },
  backModal: function(component, event, helper) {
    helper.backModal(component, event, helper);
  },
  handleSave: function(component, event, helper) {
    helper.goToForm(component, event, helper);
  },
  checkSimilar: function(component, event, helper) {
    helper.checkSimilar(component, event, helper);
  },
  handleComponentEvent: function(component, event, helper) {
    helper.handleComponentEvent(component, event, helper);
  },
  onClickInputText: function(component, event, helper) {
    helper.onClickInputText(component, event, helper);
  },
  onClickCloseAddressModal: function(component, event, helper) {
    helper.onClickCloseAddressModal(component, event, helper);
  },
  closeDropdown: function(component, event, helper) {
    helper.closeDropdown(component, event, helper);
  },
  handleComponentEventGoogle: function(component, event, helper) {
    helper.handleComponentEventGoogle(component, event);
  },
  handleLwcBack: function(component, event, helper) {
    helper.handleLwcBack(component, event, helper);
  },
  handleLwcClose: function(component, event, helper) {
    helper.closeModal(component, event, helper);
  },
  handleLwcCancel: function(component, event, helper) {
    helper.closeModal(component, event, helper);
  }
});