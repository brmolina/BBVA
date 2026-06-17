({
  doInit: function(component, event, helper) {
    let promise = helper.getInitData(component);
    promise.then(function() {
      helper.getJsonTable(component, helper);
    });
  },
  selectedRow: function(component, event, helper) {
    component.set('v.view', false);
    component.set('v.spinnerDyfr', true);
    helper.doSelectedRow(component, helper, event);
  },
  handleDyfrLoaded: function(component) {
    component.set('v.spinnerDyfr', false);
  }
});