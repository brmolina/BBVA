({
  doInit: function(component, event, helper) {
    component.set('v.isLoading', true);
    var inputAttrs = component.get('v.ahaId');
    component.set('v.recordId', inputAttrs);

    component.set('v.entityOptions', [
      { label: 'Committee', value: 'COMITE' },
      { label: 'User', value: 'user' }
    ]);
    helper.initComponent(component, event, helper);
    component.set('v.isLoading', false);
  },

  changeAmbit: function(component, event, helper) {
    var ambitId = event.getParam('value');
    component.set('v.isLoading', true);
    component.set('v.userOptions', []);
    component.set('v.selectedUserId', null);
    var inputAttrs = component.get('v.ahaId');
    component.set('v.recordId', inputAttrs);
    helper.fetchUsers(component, ambitId);
  },

  changeEntity: function(component) {
    component.set('v.selectedUserId', null);
    component.set('v.userOptions', []);
  },

  handleChangeRegion: function(component, event, helper) {
    component.set('v.selectedRegion', event.getParam('value'));
    component.set('v.selectedLevel', '');
    component.set('v.selectedOption', '');
    component.set('v.selectedOptionUser', '');
    component.set('v.levelOptions', null);
    component.set('v.ambitOptions', null);
    component.set('v.userOptions', null);
    component.find('comboLevel').set('v.value', null);
    component.find('comboAmbit').set('v.value', null);
    component.find('comboUser').set('v.value', null);
    helper.fetchLevel(component, event, helper);
  },

  handleFinish: function(component, event, helper) {
    component.set('v.show', false);
    $A.get('e.force:refreshView').fire();
  },

  handleChangeLevel: function(component, event, helper) {
    component.set('v.selectedLevel', event.getParam('value'));
    component.set('v.selectedOption', '');
    component.set('v.selectedOptionUser', '');
    component.find('comboAmbit').set('v.value', null);
    component.find('comboUser').set('v.value', null);
    helper.fetchAmbit(component, event, helper);
  },

  handleSave: function(component, event, helper) {
    component.set('v.isLoading', true);
    helper.validateRating(component, event, helper);
  },

  handleClose: function(component, event, helper) {
    helper.closeModal(component);
  }
});