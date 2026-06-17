({
  toastMes: function(component, event, messageType, messageInfo) {
    var toastEvent = $A.get('e.force:showToast');
    toastEvent.setParams({
      'type': messageType,
      'title': '',
      'message': messageType === 'SUCCESS' ? $A.get('$Label.c.Arc_Gen_Record_Update_Success') : messageInfo
    });
    toastEvent.fire();
  },
  validateActions: function(component, columns) {
    if (component.get('v.insert') === true && component.get('v.edit') === true && component.get('v.delete') === true) {
      columns = this.setAction(component, columns);
    }
    return columns;
  },
  setAction: function(component, columns) {
    var actions = this.getRowActions.bind(this, component);
    columns.push({ type: 'action', initialWidth: 20, typeAttributes: { rowActions: actions } });
    return columns;
  },
  getRowActions: function(component, row, doneCallback) {
    var actions = [];
    var activateInsert = { label: $A.get('$Label.c.Arc_Gen_Action_Insert'), name: 'insert' };
    var activateEdit = { label: $A.get('$Label.c.Arc_Gen_Action_Edit'), name: 'edit' };
    var activateDelete = { label: $A.get('$Label.c.Arc_Gen_Action_Delete'), name: 'delete' };
    if (row.agencyName === $A.get('$Label.c.Arc_Gen_Total')) {
      activateInsert.disabled = false;
      activateEdit.disabled = true;
      activateDelete.disabled = true;
    } else {
      component.set('v.selectedRowId', row.standardRowId);
      component.set('v.standardYear1Id', row.standardYear1Id);
      component.set('v.standardYear2Id', row.standardYear2Id);
      activateInsert.disabled = false;
      activateEdit.disabled = false;
      activateDelete.disabled = false;
    }
    actions.push(activateInsert);
    actions.push(activateEdit);
    actions.push(activateDelete);
    setTimeout($A.getCallback(function() {
      doneCallback(actions);
    }), 200);
  },
  insert: function(component, event) {
    var thisHelper = this; // eslint-disable-line
    var modalBody;
    var params = {
      'year1': component.get('v.year1'),
      'year2': component.get('v.year2'),
      'operationType': 'insert',
      'accHasAnalysisId': component.get('v.accHasAnalysisId'),
      'tableType': component.get('v.tableType')
    };
    $A.createComponent('c:Arc_Gen_AutoRetailTableInsertion', params,
      function(html, status, errorMessage) {
        if (status === 'SUCCESS') {
          modalBody = html;
          component.find('overlayLib').showCustomModal({
            header: $A.get('$Label.c.Lc_arce_autoRetailTable_InsertRecord'),
            body: modalBody,
            showCloseButton: true,
            closeCallback: function() {
              thisHelper.refreshTable(component, event);
            }
          });
        }
      });
  },
  edit: function(component, event) {
    var editHelper = this; // eslint-disable-line
    var editParams = {
      'year1': component.get('v.year1'),
      'year2': component.get('v.year2'),
      'operationType': 'edit',
      'accHasAnalysisId': component.get('v.accHasAnalysisId'),
      'tableType': component.get('v.tableType'),
      'selectedRowId': component.get('v.selectedRowId'),
      'standardYear1Id': component.get('v.standardYear1Id'),
      'standardYear2Id': component.get('v.standardYear2Id')
    };
    editHelper.buildComponent(component, 'c:Arc_Gen_AutoRetailTableInsertion', editParams, $A.get('$Label.c.Lc_arce_autoRetailTable_EditRecord'), event);
  },
  delete: function(component, event) {
    var deleteHelper = this; // eslint-disable-line
    var deleteParams = {
      'operationType': 'delete',
      'accHasAnalysisId': component.get('v.accHasAnalysisId'),
      'tableType': component.get('v.tableType'),
      'selectedRowId': component.get('v.selectedRowId')
    };
    deleteHelper.buildComponent(component, 'c:Arc_Gen_AutoRetailTableInsertion', deleteParams, $A.get('$Label.c.Lc_arce_autoRetailTable_DeleteRecord'), event);
  },
  buildComponent: function(component, componentName, params, header, event) {
    var body;
    var thisHelper = this; // eslint-disable-line
    $A.createComponent(componentName, params,
      function(html, status) {
        if (status === 'SUCCESS') {
          body = html;
          component.find('overlayLib').showCustomModal({
            header: header,
            body: body,
            showCloseButton: true,
            closeCallback: function() {
              thisHelper.refreshTable(component, event);
            }
          });
        }
      });
  },
  refreshTable: function(component, event, helper) {
    var aplicEvent = $A.get('e.c:Arc_Gen_AutoRetailTable_evt');
    aplicEvent.setParams({'table': component.get('v.tableType')});
    aplicEvent.fire();
  }
});