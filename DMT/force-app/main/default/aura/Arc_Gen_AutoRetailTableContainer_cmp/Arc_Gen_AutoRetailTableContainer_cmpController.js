({
  init: function(component, event, helper) {
    helper.setTableTitle(component);
    helper.setYearOptions(component);
    helper.getPreviouslySelectedYear(component, event)
      .then(function(year) {
        component.set('v.selectedValue', year);
        component.set('v.tableIsVisible', true);
      })
      .catch(function(error) {
        helper.toastMes(component, event, 'ERROR', error);
        component.set('v.tableIsVisible', false);
      });
  },
  refreshButtonHandle: function(component) {
    component.set('v.tableIsVisible', false);
    setTimeout($A.getCallback(function() {
      component.set('v.tableIsVisible', true);
    }), 2000);
  },
  yearOptionHandle: function(component, event, helper) {
    var selectedYear = component.get('v.selectedValue');
    helper.manageButtonVisibility(component, selectedYear)
      .then(function() {
        component.set('v.disableButton', false);
      })
      .catch(function() {
        component.set('v.disableButton', true);
      });
  }
});