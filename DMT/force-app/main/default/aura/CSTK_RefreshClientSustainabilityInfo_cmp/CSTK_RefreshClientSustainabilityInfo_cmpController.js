/* eslint-disable no-unused-expressions */
({
  doInit: function(component, event, helper) {
      helper.doInit(component, event, helper);
  },
  closeDialog: function(component, event, helper) {
      helper.closeDialog();
  },
  handleUpdate: function(component, event, helper) {
      helper.refreshInfo(component, event, helper);
  }
});