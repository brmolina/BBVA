({
  init: function(component, event, helper) {
    helper.checkPermission(component)
    .then(function(result) {
      return helper.isCorporates(component, event, helper);
    })
    .then(function(result) {
      return helper.checkIsRTC(component, event, helper); 
    })
    .then(function(result) {
      return helper.dataQuality(component, event, helper);
    })
    .then(function(result) {
      return helper.checkIsARP(component, event, helper);
    })
    .then(function(result) {
      return helper.arpFlowValidation(component, event, helper);
    })
    .then($A.getCallback(function(result) {
      return helper.checkIs2012P1(component, event, helper);
    }))
    .then($A.getCallback(function(result) {
      return helper.eeffAuditedValidation(component, event, helper);
    }))  
    .then(function(result) {
      return helper.validatePS(component, event, helper);
    })
    .then(function(result) {
      return helper.initDelegation(component, event, helper);
    });
  },
  handleChange: function(component, event, helper) {
    component.set('v.selectedOption', event.getParam('value'));
    component.set('v.selectedOptionUser', '');
    component.find('comboUser').set("v.value", null);
    helper.fetchUsers(component, event, helper);
  },
  handleChangeRegion: function(component, event, helper) {
    component.set('v.selectedRegion', event.getParam('value'));
    component.set('v.selectedLevel', '');
    component.set('v.selectedOption', '');
    component.set('v.selectedOptionUser', '');
    component.set('v.deleLevelWrapper', null);
    component.set('v.deleAmbitWrapper', null);
    component.set('v.deleUserWrapper', null);
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
  handleChangeUser: function(component, event, helper) {
    component.set('v.selectedOptionUser', event.getParam('value'));
  },
  toPropose: function(component, event, helper) {
    component.set('v.spinnerStatus', true);
    helper.proposeRaip(component, event, helper);
  },
  cancel: function(component, event, helper) {
    helper.cancelAction(component);
  },
  refreshPS: function(component, event, helper) {
    helper.refreshPS(component, event, helper);
  },
  refreshGCP: function(component, event, helper) {
    helper.refreshGCP(component, event, helper);
  },
  refreshWL: function(component, event, helper) {
    helper.refreshWL(component, event, helper);
  },
  finish: function(component, event, helper) {
    component.set('v.show', 'false');
    $A.get('e.force:refreshView').fire();
  }
});