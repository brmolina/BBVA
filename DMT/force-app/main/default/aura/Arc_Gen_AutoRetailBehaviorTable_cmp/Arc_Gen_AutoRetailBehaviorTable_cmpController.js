({
  init: function(component, event, helper) {
    var jsonData = {};
    var action = component.get('c.getTableData');
    var year1 = component.get('v.year1');
    var year2 = component.get('v.year2');
    var parameters = {
      'recordId': component.get('v.accHasAnalysisId'),
      'tableType': component.get('v.tableType'),
      'year1': year1.toString(),
      'year2': year2.toString()
    };
    action.setParams({
      data: parameters
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        jsonData = response.getReturnValue();
        var columns = jsonData.tableColumns;
        var data = jsonData.tableData;
        columns = helper.validateActions(component, columns);

        component.set('v.columns', columns);
        component.set('v.data', data);
        component.set('v.spinner', false);
      } else {
        helper.toastMes(component, event, 'ERROR', response.getError()[0].message);
      }
    });
    $A.enqueueAction(action);
  },
  handleRowAction: function(component, event, helper) {
    var action = event.getParam('action');
    switch (action.name) {
      case 'insert':
        helper.insert(component, event);
        break;
      case 'edit':
        helper.edit(component, event);
        break;
      case 'delete':
        helper.delete(component, event);
        break;
      default:
        helper.edit(component, event);
        break;
    }
  }
});