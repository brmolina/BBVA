({
  doInit: function(component, event, helper) {
    helper.init(component, event, helper);
  },
  closeModal: function(component, event, helper) {
    var homeEvt = $A.get('e.force:navigateToObjectHome');
    homeEvt.setParams({
      'scope': component.get('v.sObjectName')
    });
    homeEvt.fire();
  }
});