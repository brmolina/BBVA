({
  getLabelSuggested: function(component, event, helper) {
    let modelsOptions = component.get('v.options');
    for (let i = 0; i < modelsOptions.length; i++) {
      if (modelsOptions[i].value ===  component.get('v.selectedValueSubModel')) {
        component.set('v.suggestedFlow', modelsOptions[i].label);
        break;
      }
    }
  },
  getMdlOptns: function(component, event, helper) {
    const modelOptions = component.get('v.modelOptions');
    if (component.get('v.isIfis')) {
      component.set('v.options', modelOptions.ifis);
      component.set('v.loading', false);
    } else {
      component.set('v.options', modelOptions.corporates);
    }

    helper.getLabelSuggested(component, event, helper);
    helper.deleteSuggestedModel(component, event, helper);
    helper.fireWizardEvent(component, 'nextEnable', { enabled: true });
  },
  deleteSuggestedModel: function(component, event, helper) {
    var options = component.get('v.options');
    for (let i = 0; i < options.length; i++) {
      if (options[i].value === component.get('v.selectedValueSubModel')) {
        component.get('v.options').splice(i, 1);
      }
    }

    component.set('v.options', options);
    component.set('v.selectedValueSubModelSelect', options[0].value);
  },
  handleChange: function(component, event, helper) {
    let checked = event.getParam('checked');
    component.set('v.modifyFlow', checked);
    if (checked) {
      component.set('v.selectedValueSubModel', component.get('v.selectedValueSubModelSelect'));
    } else {
      component.set('v.selectedValueSubModel', component.get('v.initialSelectedValSubModel'));
    }

    const formData = component.get('v.formDataMap');
    formData.arce__RAR_rating_tool_id__c = component.get('v.selectedValueSubModel');

    component.set('v.formDataMap', formData);
    if (!component.get('v.isIfis')) {
      helper.updateExtensionTriage(component, event, helper);
    } else {
      helper.fireWizardEvent(component, 'updateAttributes', { formDataMap: formData });
    }
  },
  onChangeModel: function(component, event, helper) {
    const formData = component.get('v.formDataMap');
    formData.arce__RAR_rating_tool_id__c = component.get('v.selectedValueSubModelSelect');
    console.log('formData.arce__RAR_rating_tool_id__c', formData.arce__RAR_rating_tool_id__c);

    component.set('v.formDataMap', formData);
    if (!component.get('v.isIfis')) {
      helper.updateExtensionTriage(component, event, helper);
    } else {
      helper.fireWizardEvent(component, 'updateAttributes', { formDataMap: formData });
    }
  },
  getParticipantType: function(component, event, helper) {
    var action = component.get('c.getParticipantType');
    action.setParams({
      ahaId: component.get('v.accHasAnalysisId')
    });
    action.setCallback(this, function(response) {
      var resp = response.getReturnValue();
      var state = response.getState();
      if (state === 'SUCCESS') {
        component.set('v.participantType', resp);
        component.set('v.loading', false);
        if (resp !== 'SUBSIDIARY') {
          component.set('v.selectedValueSubModel', '2021RTC_GEN');
          component.set('v.initialSelectedValSubModel', '2021RTC_GEN');
        }
      }
    });
    $A.enqueueAction(action);
  },
  fireWizardEvent: function(component, eventType, parameters) {
    const wizardEvent = component.getEvent('wizardEvent');
    wizardEvent.setParams({
      eventType: eventType,
      parameters: parameters,
    });
    wizardEvent.fire();
  },
  updateExtensionTriage: function(component, event, helper) {
    var action = component.get('c.updateExtensionTriage');
    action.setParams({
      accHasAnalysisId: component.get('v.accHasAnalysisId'),
      formDataMap: component.get('v.formDataMap')
    });
    action.setCallback(this, function(response) {
      var resp = response.getReturnValue();
      var state = response.getState();
      if (state === 'SUCCESS') {
        component.set('v.ratingSystem', resp);
      }
    });
    $A.enqueueAction(action);
  },
});