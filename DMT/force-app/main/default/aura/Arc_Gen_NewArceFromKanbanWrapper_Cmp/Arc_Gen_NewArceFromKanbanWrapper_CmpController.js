({
  closeModel: function(component, event, helper) {
    var homeEvt = $A.get('e.force:navigateToObjectHome');
    homeEvt.setParams({
      'scope': component.get('v.sObjectName')
    });
    homeEvt.fire();
  },
  handleLookupChooseEvent: function(component, event, helper) {
    component.set('v.chosenRecordId', event.getParam('recordId'));
    component.set('v.chosenRecordLabel', event.getParam('recordLabel'));
  },
  continuetoarce: function(component, event, helper) {
    component.set('v.continue', true);
    component.set('v.isOpen', false);
  }
});