({
  doInit: function(component, event, helper) {
    var componentTarget = component.find('changespin');
    $A.util.addClass(componentTarget, 'getingdata');
    let promise1 = helper.getAHA(component, event, helper);
    promise1.then(function(resolve) {
      helper.callServices(component, event, helper);
    });
  },
  closeWindow: function(component, event, helper) {
    helper.cancelAction(component, event, helper);
  }
});