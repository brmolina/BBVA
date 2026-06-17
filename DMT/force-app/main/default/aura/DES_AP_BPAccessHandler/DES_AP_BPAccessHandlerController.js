({
  doInit: function(component, event, helper) {
    helper.onInit(component, event, helper);
  },

  handleAppEvent: function(component, event, helper) {
    helper.registerEvent(component, event, helper);
    helper.onInit(component, event, helper);
  }
});