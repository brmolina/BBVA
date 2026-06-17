({
  hinit: function(component, event) {
    var jsonData = {};
    var action = component.get('c.dataResponse');
    action.setParams({
      'recordId': component.get('v.recordId'),
      'inputClass': component.get('v.inputClass')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        jsonData = response.getReturnValue();
        if (jsonData.successResponse === true) {
          var columns = jsonData.jsonResponse.columns;
          var data = jsonData.jsonResponse.data;
          columns = this.validateActions(component, columns);

          // Rename children property of rows.
          for (let i = 0; i < data.length; i++) {
            this.renameField(data[i]);
          }

          // Sort rows by typology order.
          let sorted = this.sortRows(data);

          component.set('v.columns', columns);
          component.set('v.rows', sorted);
          component.set('v.automaticFunction', data[0].info.automatic);

          // Emit TableLoaded event.
          const ev = $A.get('e.c:Arc_Gen_TableLoadedEvent');
          ev.setParams({ table: 'PositionTable' });
          ev.fire();

          if (component.get('v.createGroupTDTable') === 'true') {
            // Create a seccond table for the Group TD aha.
            this.createSecondTable(component);
          }
          component.set('v.spinnerStatus', false);
        } else {
          this.toastMes(component, event, 'ERROR', jsonData.errorResponse);
        }
      }
    });
    $A.enqueueAction(action);
  },
  handleServiceRefresh: function(component) {
    const params = { 'recordId': component.get('v.recordId'), 'inputClass': component.get('v.inputClass') };
    const refreshAction = component.get('c.refreshAutomaticPosition');
    refreshAction.setParams(params);

    return new Promise($A.getCallback(function(resolve, reject) {
      refreshAction.setCallback(this, function(response) {
        this.handleSetCallback(response, resolve, reject);
      });
      $A.enqueueAction(refreshAction);
    }.bind(this)));
  },
  handleReload: function(component) {
    const params = { 'recordId': component.get('v.recordId'), 'inputClass': component.get('v.inputClass') };
    const dataResAction = component.get('c.dataResponse');
    dataResAction.setParams(params);

    return new Promise($A.getCallback(function(resolve, reject) {
      dataResAction.setCallback(this, function(response) {
        this.handleSetCallback(response, resolve, reject);
      });
      $A.enqueueAction(dataResAction);
    }.bind(this)));
  },
  handleSetCallback: function(response, resolve, reject) {
    // Method to handle inside setCallBack some statements
    const state = response.getState();
    if (state === 'SUCCESS') {
      resolve();
    } else {
      reject();
    }
  },
  renameField: function(jsonElement) {
    if (jsonElement.children) {
      let child = jsonElement.children;
      for (let i = 0; i < child.length; i++) {
        child[i] = this.renameField(child[i]);
        if (!jsonElement._children) {
          jsonElement._children = [];
        }
        jsonElement._children.push(child[i]);
        delete jsonElement.children;
      }
    }
    return jsonElement;
  },
  sortRows: function(rows) {
    for (let i = 0; i < rows.length; i++) {
      if (rows[i].children && rows[i].children.length > 0) {
        rows[i].children = this.sortRows(rows[i].children);
      }
    }

    return rows.sort(function(row1, row2) {
      if (!row1.order || !row2.order) {
        return 0;
      } else {
        return row1.order.order - row2.order.order;
      }
    });
  },
  validateActions: function(component, columns) {
    if (component.get('v.insert') === 'true' && component.get('v.edit') === 'true' && component.get('v.delete') === 'true') {
      columns = this.setAction(component, columns);
    }
    return columns;
  },
  setAction: function(component, columns) {
    var actions = this.getRowActions.bind(this, component);
    columns.push({ type: 'action', typeAttributes: { rowActions: actions } });
    return columns;
  },
  getRowActions: function(component, row, doneCallback) {
    var actions = [];
    var activateInsert = { label: 'Insert', name: 'insert' };
    var activateEdit = { label: 'Edit', name: 'edit' };
    var activateDelete = { label: 'Delete', name: 'delete' };
    if (row.info.clientType !== 'GROUP' || row.info.consolidatedType === '2') {
      var disabledButton = false;
      if (row.info.automatic === 'true' || row.itsTotal) {
        disabledButton = true;
      }
      activateInsert.disabled = row.info.automatic === 'true' ? true : false;
      activateEdit.disabled = row.info.isTypology === 'true';
      activateDelete.disabled = disabledButton;
    } else {
      activateInsert.disabled = true;
      activateEdit.disabled = row.info.isTypology === 'true';
      activateDelete.disabled = true;
    }
    actions.push(activateInsert);
    actions.push(activateEdit);
    actions.push(activateDelete);
    setTimeout($A.getCallback(function() {
      doneCallback(actions);
    }), 200);
  },
  edit: function(component, event) {
    let row = event.getParam('row');
    var params = {
      'exposureId': row.name,
      'accHasAnId': component.get('v.recordId'),
      'recordTypeId': row.recordTypeId
    };
    $A.createComponent(
      'c:Arc_Gen_PotitionTableEdition',
      params,
      function(html, status, errorMessage) {
        if (status === 'SUCCESS') {
          component.find('overlayLibra').showCustomModal({
            header: $A.get('$Label.c.Arc_Gen_Edit_Record'),
            body: html,
            showCloseButton: true,
            closeCallback: function() {
              var refreshVar = component.get('v.refreshVariable');
              component.set('v.refreshVariable', !refreshVar);
            }
          });
        }
      });
  },
  insert: function(component, event) {
    var action = component.get('c.getRecordTypeId');
    action.setParams({
      'recordTypeDevName': 'RPS_0001',
      'inputClass': component.get('v.inputClass')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = response.getReturnValue();
        var params = {
          'apiNameObject': 'arce__risk_position_summary__c',
          'recordTypeId': resp.recorTypeId,
          'recordId': component.get('v.recordId')
        };
        $A.createComponent(
          'c:Arc_Gen_PotitionTableInsertion',
          params,
          function(html, status, errorMessage) {
            if (status === 'SUCCESS') {
              component.find('overlayLibra').showCustomModal({
                header: $A.get('$Label.c.Arc_Gen_Insert_Record'),
                body: html,
                showCloseButton: true,
                closeCallback: function() {
                  var refreshVar = component.get('v.refreshVariable');
                  component.set('v.refreshVariable', !refreshVar);
                }
              });
            }
          }
        );
      }
    });
    $A.enqueueAction(action);
  },
  delete: function(component, event) {
    let row = event.getParam('row');
    var action = component.get('c.deleteRecord');
    action.setParams({
      'recordId': row.name,
      'inputClass': component.get('v.inputClass')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = response.getReturnValue();
        if (resp.successResponse === true) {
          var refreshVar = component.get('v.refreshVariable');
          component.set('v.refreshVariable', !refreshVar);
          this.toastMes(component, event, 'SUCCESS', 'SUCCESS');
        } else {
          this.toastMes(component, event, 'ERROR', resp.errorResponse);
        }
      } else {
        var toastEvent = $A.get('e.force:showToast');
        toastEvent.setParams({
          'type': 'ERROR',
          'title': 'ERROR!',
          'message': $A.get('$Label.c.Arc_Gen_ApexCallError')
        });
        toastEvent.fire();
      }
    });
    $A.enqueueAction(action);
  },
  toastMes: function(component, event, messageType, messageInfo) {
    var toastEvent = $A.get('e.force:showToast');
    toastEvent.setParams({
      'type': messageType,
      'title': '',
      'message': messageType === 'SUCCESS' ? $A.get('$Label.c.Arc_Gen_Record_Update_Success') : messageInfo
    });
    toastEvent.fire();
  },

  createSecondTable: function(component) {
    $A.createComponent(
      'c:Arc_Gen_PotitionBankTable',
      {
        'recordId': component.get('v.recordId'),
        'inputClass': 'Arc_Gen_Consolidated_Position_Service',
        'insert': component.get('v.insert'),
        'edit': component.get('v.edit'),
        'delete': component.get('v.delete')
      },
      function(newTable, status, errorMessage) {
        if (status === 'SUCCESS') {
          var body = component.get('v.body');
          if (!body) {
            body = [];
          }
          body.push(newTable);
          component.set('v.body', body);
        } else if (status === 'ERROR') {
          console.log('Error: ' + errorMessage);
        }
      }
    );
  }
});