({
  doInit: function(component, event, helper) {
    helper.getReasonList(component, event);
  },
  closeModal: function(component) {
    component.destroy();
  },
  siFuncion: function(component) {
    component.set('v.show', true);
    component.set('v.showbutton', false);
  },
  noFuncion: function(component) {
    component.destroy();
  },
  onSelectReason: function(component, event, helper) {
    helper.setupReasonLabel(component, event);
    component.set('v.reasonValue', event.getParam('value'));
    component.set('v.disableButtons', false);
  },
  save: function(component, event, helper) {
    component.set('v.disableButtons', true);
    helper.executeSave(component, event);
  }
});