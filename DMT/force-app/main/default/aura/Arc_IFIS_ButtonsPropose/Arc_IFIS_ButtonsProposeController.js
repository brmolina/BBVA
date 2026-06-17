({
  doInit: function(component, event, helper) {
    helper.initComponent(component, event, helper);
  },

  handleSave: function(component, event, helper) {
    component.set('v.show', 'false');
    $A.get('e.force:refreshView').fire();
  },

  handleChange: function(component, event, helper) {
    component.set('v.selectedOption', event.getParam('value'));
    component.set('v.selectedOptionUser', '');
    component.find('comboUser').set('v.value', null);
    helper.fetchUsers(component, event, helper);
  },

  handleClose: function(component, event, helper) {
    helper.cancelAction(component);
  },

  refreshPS: function(component, event, helper) {
    helper.refreshPS(component, event, helper);
  },

  handleChangeRegion: function(component, event, helper) {
    component.set('v.selectedRegion', event.getParam('value'));
    component.set('v.selectedLevel', '');
    component.set('v.selectedOption', '');
    component.set('v.selectedOptionUser', '');
    component.set('v.deleLevelWrapper', null);
    component.set('v.deleAmbitWrapper', null);
    component.set('v.deleUserWrapper', null);
    component.find('comboLevel').set('v.value', null);
    component.find('comboAmbit').set('v.value', null);
    component.find('comboUser').set('v.value', null);
    helper.fetchLevel(component, event, helper);
  },

  handleChangeLevel: function(component, event, helper) {
    component.set('v.selectedLevel', event.getParam('value'));
    component.set('v.selectedOption', '');
    component.set('v.selectedOptionUser', '');
    component.find('comboAmbit').set('v.value', null);
    component.find('comboUser').set('v.value', null);
    helper.fetchAmbit(component, event, helper);
  },

  handleChangeUser: function(component, event, helper) {
    component.set('v.selectedOptionUser', event.getParam('value'));
  },

  toPropose: function(component, event, helper) {
    component.set('v.isLoading', true);
    helper.proposeRating(component, event, helper);
  },
});