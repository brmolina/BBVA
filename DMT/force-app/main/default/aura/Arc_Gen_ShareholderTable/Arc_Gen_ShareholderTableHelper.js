({
  getData: function(component, event, helper, headers) {
    var action = component.get('c.getData');
    action.setParams({
      recordId: component.get('v.recordId'),
      columns2Show: headers
    });
    action.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        var resp = JSON.parse(response.getReturnValue());
        if (resp.hasInfo === false) {
          component.set('v.showCmp', false);
        } else {
          component.set('v.showCmp', true);
          if (headers.length === 0) {
            component.set('v.availables', resp.columnsInfo);
          }
          var maxColumns = component.get('v.availables');
          if (maxColumns.length > 7) {
            component.set('v.showSpinner', false);
            component.set('v.showDualList', true);
            helper.createOptions(component, component.get('v.availables'));
            helper.buildMaxColumnData(component, resp.columnsInfo, resp.rowData);
          } else {
            component.set('v.showSpinner', false);
            component.set('v.headers', resp.columnsInfo);
            component.set('v.data', resp.rowData);
            component.set('v.values', resp.columnsInfo);
            component.set('v.showDualList', false);
            helper.createOptions(component, component.get('v.availables'));
          }
        }
      }
    });
    $A.enqueueAction(action);
  },
  buildMaxColumnData: function(component, columns, rows) {
    var newColumn = [];
    var newRows = [];
    for (var i = 0; i < 7; i++) {
      newColumn.push(columns[i]);
    }
    for (var row of rows) {
      var aux = [];
      for (var j = 0; j < 7; j++) {
        aux.push(row[j]);
      }
      newRows.push(aux);
    }
    component.set('v.headers', newColumn);
    component.set('v.data', newRows);
    component.set('v.values', newColumn);
  },
  createOptions: function(component, columnsInfo) {
    var options = [];
    for (var column of columnsInfo) {
      if (column !== $A.get('$Label.c.Arc_Gen_Shareholder')) {
        options.push({ label: column, value: column });
      }
    }
    component.set('v.options', options);
  }
});