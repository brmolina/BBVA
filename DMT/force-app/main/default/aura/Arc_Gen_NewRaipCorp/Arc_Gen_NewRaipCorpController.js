({
  doInit: function(component, event, helper) {
    helper.onInit(component, event, helper);
  },
  handleNext: function(component, event, helper) {
    helper.nextStep(component, event, helper);
  },
  handleFfssSelection: function(component, event, helper) {
    helper.ffssSelection(component, event, helper);
  },
  handleRatingTypeChange: function(component, event, helper) {
    helper.enableNextButton(component, true);
  },
  handleIRPTypeChange: function(component, event, helper) {
    helper.changeIRPType(component, event, helper);
  },
  handleModlSelect: function(component, event, helper) {
    helper.modlSelection(component, event, helper);
  }
});