({
  doInit: function(cmp, event, helper) {
    helper.doInit(cmp, event, helper);
    helper.onInit(cmp, event, helper);
  },
  openTable: function(cmp, event, helper) {
    cmp.set('v.spinnerGrid', true);
    cmp.set('v.isOpen', true);
    helper.initializeDataTable(cmp, event, helper);
    helper.getTableData(cmp, event, helper);
  },
  closeTable: function(cmp, event, helper) {
    cmp.set('v.isOpen', false);
  },
  saveDataTable: function(cmp, event, helper) {
    helper.handleSaveData(cmp, event, helper);
  },
  handleSort: function(component, event, helper) {
    var sortField = event.getParam('fieldName');
    var sortDirection = event.getParam('sortDirection');
    console.log('sort direction : ' + sortDirection);
    component.set('v.sortField', sortField);
    component.set('v.sortDirection', sortDirection);
    helper.sortData(component, sortField, sortDirection);
  },
  handleAppEvent: function(component, event, helper) {
    helper.doInit(component, event, helper);
    helper.onInit(component, event, helper);
  }
});