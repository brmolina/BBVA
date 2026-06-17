({
  init: function(component, event, helper) {
    const inputAttrs = component.get('v.inputAttributes');
    component.set('v.recordId', inputAttrs.recordId);
    
    helper.getArceConfigs(component, event, helper)
      .then((function() {
        return helper.isOverrideComplete(component, event, helper); 
      }))
      .then((function() {
        return helper.dataQuality(component, event, helper);
      }))
      .then((function() {
        return helper.validatePS(component, event, helper);
      }))
      .then((function() {
        return helper.isESGPersistanceActive(component, event, helper);
      }))
      .then((function() {
        return helper.getSalesEngine(component, event, helper);
      }))
      .then((function(result) {
        if (result !== 'OK') {
          helper.showToast('warning', result);
        }
        return helper.getRatingData(component, event, helper);
      }))
      .then((function(result) {
        return helper.checkScoreAlert(component, event, helper);
      }))
      .catch((function(errMsg) {
        helper.showToast('error', errMsg);
      }))
      .finally(() => {
        component.set('v.loading', false);
      });
  },
  validateAction: function(component, event, helper) {
    component.set('v.loading', true);
    helper.limitAdvisor(component, event, helper)
    .then(function() {
        if (component.get('v.isESGActive')) {
          helper.persistenceDataEsg(component, event, helper);
          helper.persistenceEsg(component, event, helper);
        }
        return helper.validating(component, event, helper);
      })
      .catch(function(error) {
        component.set('v.success', false);
        component.set('v.errorMessage', error);
      });
  },
  changeAmbit: function(component, event, helper) {
    var ambitId = event.getParam('value');
    var recordId = component.get('v.recordId');
    component.set('v.loading', true);
    component.set('v.userOptions', []);
    component.set('v.selectedUserId', null);
    var inputAttrs = component.get('v.inputAttributes');
    component.set('v.recordId', inputAttrs.recordId);
    helper.fetchUsers(component, event, helper, ambitId, recordId);
  },
  changeEntity: function(component, event, helper) {
    component.set('v.selectedUserId', null);
    component.set('v.userOptions', []);
  },
  finish: function(component, event, helper) {
    component.set('v.show', false);
    $A.get('e.force:refreshView').fire();
  },
  cancel: function(component, event, helper) {
    component.set('v.show', false);
    component.destroy();
  },
  handleChangeRegion: function(component, event, helper) {
    component.set('v.selectedRegion', event.getParam('value'));
    component.set('v.selectedLevel', '');
    component.set('v.selectedOption', '');
    component.set('v.selectedOptionUser', '');
    component.set('v.levelOptions', null);
    component.set('v.ambitOptions', null);
    component.set('v.userOptions', null);
    component.find('comboLevel').set("v.value", null);
    component.find('comboAmbit').set("v.value", null);
    component.find('comboUser').set("v.value", null);
    helper.fetchLevel(component, event, helper);
  },
  handleChangeLevel: function(component, event, helper) {
    component.set('v.selectedLevel', event.getParam('value'));
    component.set('v.selectedOption', '');
    component.set('v.selectedOptionUser', '');
    component.find('comboAmbit').set("v.value", null);
    component.find('comboUser').set("v.value", null);
    helper.fetchAmbit(component, event, helper);
  },
  refreshPS: function(component, event, helper) {
    helper.refreshPS(component, event, helper);
  }
});