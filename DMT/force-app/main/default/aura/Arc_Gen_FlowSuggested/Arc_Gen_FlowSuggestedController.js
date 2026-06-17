({
  init: function(component, event, helper) {
    helper.fireWizardEvent(component, 'nextEnable', { enabled: false });
    const formData = component.get('v.formDataMap');
    component.set('v.initialSelectedValSubModel', formData.arce__RAR_rating_tool_id__c);
    component.set('v.selectedValueSubModel', formData.arce__RAR_rating_tool_id__c);
    if (!component.get('v.isIfis')) {
      helper.updateExtensionTriage(component, event);
      helper.getParticipantType(component, event, helper);
    }

    helper.getMdlOptns(component, event, helper);
  },
  handleChange: function(component, event, helper) {
    helper.handleChange(component, event, helper);
  },
  onChangeModel: function(component, event, helper) {
    helper.onChangeModel(component, event, helper);
  },
});