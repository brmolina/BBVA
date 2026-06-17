({
    init: function (component, event, helper) {
        helper.getDataFromGroup(component, helper);
        helper.setTable(component);
    },
    filterSearch: function (component, event, helper) {
      if(event.getSource().get('v.value') !== undefined && event.getSource().get('v.value').length > 2) {
        helper.getFilterDataFromGroup(component, event, helper);
      } else {
        component.set('v.tableData', component.get('v.originalData'));
        helper.setData(component);
      }
    },
    closeModal: function (component, event, helper) {
        window.location.href = component.get('v.lastUrl');
    }
});