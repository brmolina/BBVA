({
  doInit: function(component, event, helper) {
    Promise.all([
      helper.callPersistenceMdt(component),
      helper.callArceConfigMdt(component, event, helper),
    ])
      .then(function() {
        helper.setDefaults(component, event, helper);
      })
      .catch(function(error) {
        helper.fireEventWizard(component, 'ratingSystemChanged', { formDataMap: {}, error });
      });
  },
  handleChange: function(component, event, helper) {
    const auraIds = helper.getAuraIds();
    const eventSource = event.getSource();
    const eventValue = eventSource.get('v.value');
    const eventLocalId = eventSource.getLocalId();

    if (eventLocalId === 'entityType') {
      helper.createClientSelector(component, eventValue);
    }

    helper.handleChangeForm(component, event, helper, auraIds);
  },
  handleChangeClient: function(component, event, helper) {
    const isIFIS = component.get('v.entityTypeValue') === 'ifis';

    helper.setClientValues(component);

    if (isIFIS) {
      helper.setIfisModelOption(component, event, helper);
    }
  },
  handleParentSubsidiaryChange: function(component, event, helper) {
    helper.applyParentSubsidiaryDefaults(component, event, helper);
  },
  onClickEnableSelection: function(component, event, helper) {
    const auraIds = helper.getAuraIds();

    helper.clearValues(component, auraIds);
    helper.fireRefreshViewForm(component);
    helper.fireEventWizard(component, 'ratingSystemChanged', { formDataMap: {} });
  }
});