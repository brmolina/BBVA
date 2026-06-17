/* eslint-disable no-unused-expressions */
({
  doInit: function(component, event, helper) {
    helper.setColumns(component);
  },

  handleRowAction: function(cmp, event, helper) {
    var action = event.getParam('action');
    var row = event.getParam('row');
    var sameRow = false;
    if (action.name === 'view_details') {
      if (cmp.get('v.lastDetailOpened') !== row) {
        cmp.set('v.lastDetailOpened', row);
      } else {
        sameRow = true;
      }
      helper.showRowDetails(cmp, helper, row, sameRow);
    } else {
      console.error('unknow action: ' + action);
    }
  },

  handlePrevious: function(component, event, helper) {
    //notify with event to parent
    let event2 = component.getEvent('KPI_Search_evt');
    event2.setParam('page', component.get('v.currentPage') - 1);
    event2.setParam('size', component.get('v.pageSize'));
    event2.fire();
  },

  handleNext: function(component, event, helper) {
    let event2 = component.getEvent('KPI_Search_evt');
    event2.setParam('page', component.get('v.currentPage') + 1);
    event2.setParam('size', component.get('v.pageSize'));
    event2.fire();
  },

  closeModal: function(component) {
    component.set('v.body', null);
  },
  handleSaveEdition: function(component, event, helper) {
    var draftValues = event.getParam('draftValues');
    helper.saveEdition(component, draftValues, helper);
  }
});