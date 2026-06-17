({
  init: function(component, event, helper) {
    var header = [];
    helper.getData(component, event, helper, header);
  },
  handleChange: function(component, event) {
    var selectedOptionValue = event.getParam('value');
    component.set('v.values', selectedOptionValue);
  },
  updateTable: function(component, event, helper) {
    component.set('v.showSpinner', true);
    helper.getData(component, event, helper, component.get('v.values'));
  }
});