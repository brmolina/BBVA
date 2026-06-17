({
  doInit: function(component, event, helper) {
    helper.getRatingData(component, helper);
    component.set('v.warning', $A.get('{!$Label.c.Arc_Gen_RAIP_GBL_AdjCorporateValidateMsg}'));
  },
  validateRating: function(component, event, helper) {
    component.set('v.showScore', false);
    component.set('v.loading', true);
    helper.validating(component, helper);
  },
  cancel: function(component, event, helper) {
    component.set('v.show', false);
    component.destroy();
  }
});