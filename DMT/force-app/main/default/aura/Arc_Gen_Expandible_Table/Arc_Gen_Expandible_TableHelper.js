({
  getHeaderDate: function(component) {
    var action = component.get('c.getHeaderDate');
    action.setParams({
      'recordId': component.get('v.recordId')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var headerDate = response.getReturnValue();
        if (headerDate !== null) {
          component.set('v.headerDate', headerDate);
        }

        // Emit TableLoaded event.
        const event = $A.get('e.c:Arc_Gen_TableLoadedEvent');
        event.setParams({ table: 'PolicieTable' });
        event.fire();
      }
    });
    $A.enqueueAction(action);
  },
  getTypeOfAnalysis: function(component) {
    var action = component.get('c.getTypeOfAnalysis');
    action.setParams({
      'recordId': component.get('v.recordId')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var arrResp = JSON.parse(response.getReturnValue());
        component.set('v.analysisType', arrResp[0]);
        component.set('v.statusPersServices', arrResp[1]);
        component.set('v.callLimitsRefresh', arrResp[2]);
      }
    });
    $A.enqueueAction(action);
  },
  checkInSanction: function(component) {
    var action = component.get('c.checkInSanction');
    action.setParams({
      'recordId': component.get('v.recordId')
    });
    return new Promise($A.getCallback(function(resolve, reject) {
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var isSanction = response.getReturnValue();
          if (isSanction) {
            component.set('v.edit', 'false');
            component.set('v.insert', 'false');
            component.set('v.delete', 'false');
          }
          resolve();
        } else {
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  getTableData: function(component) {
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
        this.buildTable(component, jsonData.jsonResponse);
        if (!component.get('v.statusPersServices') && !component.get('v.callLimitsRefresh')) {
          this.persistenceAllLimits(component);
        }
        component.set('v.errorMessage', '');
      } else {
        component.set('v.errorMessage', response.getError()[0].message);
      }
    });
    $A.enqueueAction(action);
  },
  buildTable: function(component, jsonData) {
    for (let i = 0; i < jsonData.data.length; i++) {
      jsonData.data[i] = this.renameField(jsonData.data[i]);
    }
    var data2SplitColumn =  component.get('v.spliceColumn');
    var splitColumnData = data2SplitColumn.split(';');
    var splitedColumnData1 = splitColumnData[0].split(',');
    var splitedColumnData2 = splitColumnData[1].split(',');

    var data2SplitRow = component.get('v.spliceRow');
    var splitRowData = data2SplitRow.split(';');
    var splitedRowData1 = splitRowData[0].split(',');
    var splitedRowData2 = splitRowData[1].split(',');

    jsonData.data.splice(splitedRowData1[0], splitedRowData1[1]);
    jsonData.data.splice(splitedRowData2[0], splitedRowData2[1]);

    jsonData.columns = this.setActions(component, jsonData.columns);
    jsonData.columns.splice(splitedColumnData1[0], splitedColumnData1[1]);
    jsonData.columns.splice(splitedColumnData2[0], splitedColumnData2[1]);
    component.set('v.gridColumns', jsonData.columns);
    component.set('v.gridData', jsonData.data);
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
  setActions: function(component, columns) {
    var actions = this.getRowActions.bind(this, component);
    if (component.get('v.edit') || component.get('v.insert') || component.get('v.delete')) {
      columns.push({ type: 'action', typeAttributes: { rowActions: actions } });
    }
    return columns;
  },
  getRowActions: function(component, row, doneCallback) {
    var actions = [];
    this.validaInsert(component, row, doneCallback, actions);
    if (component.get('v.edit')) {
      var editOp = { label: $A.get('$Label.c.Arc_Gen_Action_Edit'), name: 'edit' };
      if (component.get('v.edit') === 'false') {
        editOp = { label: $A.get('$Label.c.Arc_Gen_Action_Show'), name: 'show' };
        component.set('v.readOnly', true);
      }
      if (row.info.typologyCode === 'TP_0006') {
        editOp.disabled = true;
      }
      actions.push(editOp);
    }
    if (component.get('v.delete') === 'true') {
      var deleteOp = { label: $A.get('$Label.c.Arc_Gen_Action_Delete'), name: 'delete' };
      if (row.info.level === '1') {
        deleteOp.disabled = true;
      }
      if (row.info.level === '2' && (row.info.typologyCode === $A.get('$Label.c.Arc_Gen_TP_0008') || row.info.typologyCode === $A.get('$Label.c.Arc_Gen_TP_0002'))) {
        deleteOp.disabled = false;
      } else if (row.info.level === '2' && (row.info.typologyCode)) {
        deleteOp.disabled = true;
      }
      actions.push(deleteOp);
    }
    setTimeout($A.getCallback(function() {
      doneCallback(actions);
    }), 200);
  },
  insertRecords: function(component, event) {
    var row = event.getParam('row');
    var recordtype = row.info.typologyCode + 'P';
    this.insertRecordsLv2(component, row, recordtype);
  },
  insertRecordsLv2: function(component, row, recordtype) {
    var action = component.get('c.getRecordId');
    action.setParams({
      'recordTypeName': recordtype
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var recId = response.getReturnValue();
        var params = {
          'parentId': row.name,
          'apiNameObject': 'arce__limits_exposures__c',
          'recordTypeId': recId,
          'accHasAId': component.get('v.recordId'),
          'tipology': row.info.typologyCode,
          'inputClass': component.get('v.inputClass')
        };
        $A.createComponent(
          component.get('v.insertName'),
          params,
          function(html, status, errorMessage) {
            if (status === 'SUCCESS') {
              component.find('overlayLib').showCustomModal({
                header: $A.get('$Label.c.Arc_Gen_Insert_Record'),
                body: html,
                showCloseButton: true,
                cssClass: 'cArc_Gen_Insertion',
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
  editRecords: function(component, event) {
    var row = event.getParam('row');
    var isProduct = false;
    var typoTypeName = row.info.typologyCode;
    if (row.info.level === '2' && !row.info.typologyCode) {
      isProduct = true;
      typoTypeName = row.tipology;
    }
    var newAttributes = {
      'recordId': row.name,
      'accHasAId': component.get('v.recordId'),
      'tipology': (row.info.level === '3') ? row.tipology : typoTypeName,
      'producto': (row.info.level === '3') ? true : isProduct,
      'recordtypeid': row.info.recordtypeid,
      'readOnly': component.get('v.readOnly')
    };
    $A.createComponent(component.get('v.editName'), newAttributes, function(html, status, errorMessage) {
      if (status === 'SUCCESS') {
        component.find('overlayLib').showCustomModal({
          header: $A.get('$Label.c.Arc_Gen_Edit_Record'),
          body: html,
          showCloseButton: true,
          closeCallback: function() {
            var refreshVar = component.get('v.refreshVariable');
            component.set('v.refreshVariable', !refreshVar);
          }
        });
      } else {
        this.toastMessages(status, errorMessage);
      }
    });
  },
  persDelRecords: function(component, event, helper, row) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var action = component.get('c.delLimitPersService');
      action.setParams({
        'accHasId': component.get('v.recordId'),
        'recordId': row.name
      });
      action.setCallback(this, function(response) {
        if (response.getState() === 'SUCCESS') {
          let resp = response.getReturnValue();
          if (resp === true) {
            resolve();
          } else {
            reject($A.get('$Label.c.Arc_Gen_ServicePersistenceError'));
          }
        } else {
          reject($A.get('$Label.c.Arc_Gen_ApexCallError'));
        }
      });
      $A.enqueueAction(action);
    }));
  },
  deleteRecords: function(component, event, row) {
    component.set('v.show', false);
    var action = component.get('c.deleteRecords');
    action.setParams({
      'recordId': row.name
    });
    action.setCallback(this, function(response) {
      var res = response.getReturnValue();
      this.refresh(component, event);
      this.toastMessages(res.response, res.message);
    });
    $A.enqueueAction(action);
  },
  toastMessages: function(status, message) {
    switch (status) {
      case 'SUCCESS':
        var toastSuccess = $A.get('e.force:showToast');
        toastSuccess.setParams({
          'title': $A.get('$Label.c.Arc_Gen_Toast_Success_Title'),
          'type': 'success',
          'mode': 'sticky',
          'duration': '8000',
          'message': $A.get('$Label.c.Arc_Gen_Toast_Success')
        });
        toastSuccess.fire();
        break;
      case 'INCOMPLETE':
        var toastIncomplete = $A.get('e.force:showToast');
        toastIncomplete.setParams({
          'title': 'Error!',
          'type': 'error',
          'mode': 'sticky',
          'duration': '8000',
          'message': $A.get('$Label.c.Arc_Gen_Toas_Unknown')
        });
        toastIncomplete.fire();
        break;
      case 'ERROR':
        var toastError = $A.get('e.force:showToast');
        toastError.setParams({
          'title': 'Error!',
          'type': 'error',
          'mode': 'sticky',
          'duration': '8000',
          'message': $A.get('$Label.c.Arc_Gen_Toast_Unknown_Error') + ' ' + message
        });
        toastError.fire();
        break;
      default:
        var toastDefault = $A.get('e.force:showToast');
        toastDefault.setParams({
          'title': 'Error!',
          'type': 'error',
          'mode': 'sticky',
          'duration': '8000',
          'message': $A.get('$Label.c.Arc_Gen_Toast_Unknown_Status')
        });
        toastDefault.fire();
    }
  },
  validaInsert: function(component, row, doneCallback, actions) {
    if (component.get('v.insert') === 'true') {
      var insert = { label: $A.get('$Label.c.Arc_Gen_Action_Insert'), name: 'insert' };
      switch (row.info.level) {
        case '1':
          insert.disabled = true;
          if (row.info.clientType !== 'Group') {
            insert.disabled = this.insertLvl1(row);
          }
          break;
        case '2':
          insert.disabled = true;
          if (row.info.clientType !== 'Group') {
            insert.disabled = this.insertLvl2(row);
          }
          break;
        case '3':
          insert.disabled = true;
          break;
      }
      actions.push(insert);
    }
    return actions;
  },
  insertLvl1: function(row) {
    return row.info.typologyCode === $A.get('$Label.c.Arc_Gen_TP_0008') || row.info.typologyCode === $A.get('$Label.c.Arc_Gen_TP_0002') ? false : true;
  },
  insertLvl2: function(row) {
    return row.info.typologyCode === $A.get('$Label.c.Arc_Gen_TP_0008') || row.info.typologyCode === $A.get('$Label.c.Arc_Gen_TP_0002') ? true : false;
  },
  refresh: function(component, event) {
    this.getTableData(component);
  },
  getProposeInfo: function(component, event, helper) {
    var action = component.get('c.getLastProposeInfo');
    action.setParams({
      'recordId': component.get('v.recordId')
    });
    action.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        var resp = response.getReturnValue();
        if (resp === 'TRUE') {
          helper.refresh(component, event);
          helper.toastMessages('SUCCESS', '');
        } else {
          component.set('v.errorMessage', resp);
        }
      } else {
        component.set('v.errorMessage', response.getError()[0].message);
      }
    });
    $A.enqueueAction(action);
  },
  handleRefreshEvt: function(component, event, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var action = component.get('c.changeServiceFlag');
      action.setParams({
        'recordId': component.get('v.recordId')
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          let resp = response.getReturnValue();
          if (resp.successResponse === true) {
            resolve();
          } else {
            helper.toastMessages('ERROR', resp.errorResponse);
            reject();
          }
        } else {
          helper.toastMessages('ERROR', $A.get('$Label.c.Arc_Gen_ApexCallError'));
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  persistenceAllLimits: function(component) {
    var action = component.get('c.allLimitsPersistence');
    action.setParams({
      'accHasId': component.get('v.recordId')
    });
    action.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        var resp = response.getReturnValue();
        if (resp === true) {
          component.set('v.statusPersServices', true);
        } else {
          this.toastMessages('ERROR', $A.get('$Label.c.Arc_Gen_ServicePersistenceError'));
        }
      }
    });
    $A.enqueueAction(action);
  }
});