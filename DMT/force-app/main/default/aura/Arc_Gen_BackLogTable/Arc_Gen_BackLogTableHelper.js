({
  hinit: function(component) {
    var action = component.get('c.getTableData');
    action.setParams({
      'recordId': component.get('v.recordId')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = response.getReturnValue();
        if (resp.backLogData.salesX === undefined) {
          resp.backLogData.salesX = 0;
        }
        if (resp.backLogData.salesY === undefined) {
          resp.backLogData.salesY = 0;
        }
        if (resp.backLogData.importX === undefined) {
          resp.backLogData.importX = 0;
        }
        if (resp.backLogData.importY === undefined) {
          resp.backLogData.importY = 0;
        }
        if (resp.errorResponse === null || resp.errorResponse === undefined) {
          this.printTable(component, resp);
        } else {
          component.set('v.errorResponse', resp.errorResponse);
          component.set('v.showSpinTable', false);
        }
      }
    });
    $A.enqueueAction(action);
  },
  printTable: function(component, resp) {
    var backlog = resp.backLogData;
    var salesXPercent = backlog.salesX + '%';
    var salesYPercent = backlog.salesY + '%';
    var importX = backlog.importX + '';
    var importY = backlog.importY + '';
    var columns = [{label: '', fieldName: 'backLog', type: 'text', cellAttributes: { alignment: 'center' }},
      {label: resp.currentYear, fieldName: 'yearX', type: 'text', cellAttributes: { alignment: 'center' }},
      {label: resp.lastYear, fieldName: 'yearY', type: 'text', cellAttributes: { alignment: 'center' }}];
    var data = [
      {backLog: $A.get('$Label.c.Arc_Gen_Backlog'), yearX: importX, yearY: importY},
      {backLog: $A.get('$Label.c.Arc_Gen_BacklogSales'), yearX: salesXPercent, yearY: salesYPercent}
    ];
    columns = this.setActionEdit(component, columns);
    component.set('v.columns', columns);
    component.set('v.data', data);
    component.set('v.showSpinTable', false);
  },
  setActionEdit: function(component, columns) {
    if (component.get('v.edit') === 'true') {
      var actions = [];
      actions.push({ label: $A.get('$Label.c.Arc_Gen_Action_Edit'), name: 'edit' });
      columns.push({ type: 'action', typeAttributes: { rowActions: actions } });
    }
    return columns;
  },
  hhandleSubmit: function(component, event) {
    event.preventDefault();
    var fields = event.getParam('fields');
    component.find('BackLogEdit_table').submit(fields);
  }
});