({
  init: function(component, event, helper) {
    helper.getAhaExtension(component, event, helper);
    helper.getParticipantType(component, event, helper);
    helper.returnJsonFlow(component, event, helper);
  },
  handleSubmit: function(component, event, helper) {
    event.preventDefault();
    helper.handleSubmit(component, event, helper);
  },
  handleNext: function(component, event, helper) {
    helper.nextStep(component, event, helper);
  },
  handleChangeField: function(component, event, helper) {
    helper.changeFieldGeneral(component, event, helper);
  },
  handleChangeTreasury: function(component, event, helper) {
    helper.handleChangeTreasury(component, event, helper);
    helper.changeFieldGeneral(component, event, helper);
  },
  handleChangeEEFF: function(component, event, helper) {
    helper.handleChangeEEFF(component, event, helper);
    helper.changeFieldGeneral(component, event, helper);
  },
  handleChangeExplicit: function(component, event, helper) {
    helper.handleChangeExplicit(component, event, helper);
    helper.changeFieldGeneral(component, event, helper);
  },
  handleChangeCore: function(component, event, helper) {
    helper.handleChangeCore(component, event, helper);
    helper.changeFieldGeneral(component, event, helper);
  },
  handleChangeCorporate: function(component, event, helper) {
    helper.handleChangeCorporate(component, event, helper);
    helper.changeFieldGeneral(component, event, helper);
  },
  handleChangeEEUU: function(component, event, helper) {
    helper.handleChangeEEUU(component, event, helper);
    helper.changeFieldGeneral(component, event, helper);
  },
  handleChangeIg: function(component, event, helper) {
    helper.handleChangeIg(component, event, helper);
    helper.changeFieldGeneral(component, event, helper);
  },
});