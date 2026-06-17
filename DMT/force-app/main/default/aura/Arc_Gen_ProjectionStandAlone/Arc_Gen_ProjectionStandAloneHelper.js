({
  getColumns: function(component) {
    var columns = [];
    var action = component.get('c.getSimulationData');
    action.setParams({
      recordId: component.get('v.accHasAnalysisId'),
      proposalId: (component.get('v.proposalFolderId') !== '!proposalFolderId' && component.get('v.proposalFolderId') !== undefined) ? component.get('v.proposalFolderId') : null
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var recordList = response.getReturnValue();
        columns.push({
          label: '',
          fieldName: 0,
          type: 'text',
          editable: false,
        });
        this.responseStandAlone(component, recordList, columns);
      } else if (state === 'ERROR') {
        var errors = response.getError();
        let errorMsg;

        if (errors[0] && errors[0].message) {
          errorMsg = errors[0].message;
        } else {
          errorMsg = 'Error: An unexpected error has ocurred, please try again later.';
        }
        component.set('v.msgError', errorMsg);
      }
      component.set('v.spinner', false);
    });
    $A.enqueueAction(action);
  },
  createTableStructure: function(cmp, recordList, mapValues) {
    var dataBaseCase = cmp.get('v.dataBaseCase');
    var dataScenario = [];
    var dataUpCase = cmp.get('v.dataUpCase');
    var dataDownCase = cmp.get('v.dataDownCase');
    var gridData = [];

    recordList.forEach(function(element, index) {
      var shortValue =
        element.arce__Simulation_Short_Scale_Value__c !== undefined
          ? element.arce__Simulation_Short_Scale_Value__c
          : '--';
      if (element.arce__Scenario_Type__c === 'Base Case') {
        dataBaseCase[0][element.arce__Projection_Header__c] = shortValue;
      } else if (element.arce__Scenario_Type__c === 'Up') {
        dataUpCase[0][element.arce__Projection_Header__c] = shortValue;
      } else if (element.arce__Scenario_Type__c === 'Down') {
        dataDownCase[0][element.arce__Projection_Header__c] = shortValue;
      }
    });
    dataScenario.push(dataUpCase[0]);
    dataScenario.push(dataDownCase[0]);
    gridData.push(dataBaseCase[0]);
    gridData.push('');
    cmp.set('v.dataScenario', dataScenario);
    this.getKeysData(cmp, recordList, mapValues, gridData);
  },
  fillTables: function(cmp, firstKey, datapush) {
    var projectionData = cmp.get('v.projectionData');
    var sizeData = datapush.length;
    if (projectionData.length !== 0) {
      projectionData.forEach(function(element, index) {
        if (element.arce__Scenario_Type__c === 'Base Case') {
          const map2 = new Map(Object.entries(element));
          datapush[sizeData - 1][element.arce__Projection_Header__c] =
          new Intl.NumberFormat('de-DE').format(map2.get(firstKey)) !== undefined ? new Intl.NumberFormat('de-DE').format(map2.get(firstKey)) : '--';
        }
      });
    }
  },
  getKeysData: function(cmp, response, mapValues, data) {
    var firstKey = [];
    var firstValue = [];
    var datapush = [];
    var gridData = [];

    var mapLabelAPI = new Map(Object.entries(mapValues.mapLabelAPI));

    for (let value of mapLabelAPI.values()) {
      var controlMapValue = new Map(Object.entries(value));
      [ firstKey ] = controlMapValue.keys();
      [ firstValue ] = controlMapValue.values();
      datapush.push({ id: firstKey, 0: firstValue });
      this.fillTables(cmp, firstKey, datapush);
    }

    cmp.set('v.dataKey', datapush);
    gridData.push('BASE CASE  metrics Summary');
    gridData._children = datapush;
    data.push(gridData);
    cmp.set('v.gridData', data);
    var expandedRows = [ 'BASE CASE  metrics Summary' ];
    cmp.set('v.gridExpandedRows', expandedRows);
    cmp.set('v.spinner', false);
  },
  checkControlValues: function(component, helper) {
    component.set('v.spinner', true);
    var action = component.get('c.checkControlValues');
    var pFolderId = helper.getProposalFolderId(component);
    action.setParams({
      recordId: component.get('v.accHasAnalysisId'),
      scenario: null,
      isSimulation: true,
      proposalId: pFolderId
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var responseCall = response.getReturnValue();
        if (Object.keys(responseCall).length === 0) {
          component.set('v.msgTable', 'si');
          component.set(
            'v.scenarioNotCalculated',
            null
          );
          component.set('v.spinner', false);
        } else {
          component.set('v.projectionPerspective', responseCall.projectionPerspective);
          this.getColumns(component);
          var userCanEdit = component.get('v.userCanEdit');
          if (userCanEdit !== undefined && userCanEdit !== null) {
            if (userCanEdit === true) {
              this.projectionCalculated(component, responseCall, helper);
            } else {
              component.set('v.msgTable', 'no');
            }
            } else {
            this.projectionCalculated(component, responseCall, helper);
          }
        }
      } else if (state === 'ERROR') {
        helper.setErrorsByResponse(component, response);
      }

    });
    $A.enqueueAction(action);
  },
  getProposalFolderId: function(component) {
    return component.get('v.proposalFolderId') !== '!proposalFolderId' && component.get('v.proposalFolderId') !== undefined ? component.get('v.proposalFolderId') : null;
  },
  setErrorsByResponse: function(component, response) {
    var errors = response.getError();
    let errorMsg;
    if (errors[0] && errors[0].message) {
      errorMsg = errors[0].message;
    } else {
      errorMsg = 'Error: An unexpected error has ocurred, please try again later.';
    }
    component.set('v.msgError', errorMsg);
    component.set('v.spinner', false);
  },
  projectionCalculated: function(component, responseCall, helper) {
    if (responseCall.controlValues.Up === false  || responseCall.controlValues.Down === false) {
      var scenarioNotCalculated = [
        ...new Set(responseCall.scenarioNoCalculated),
      ];
      component.set('v.msgTable', 'si');
      component.set(
        'v.scenarioNotCalculated',
        scenarioNotCalculated.filter(n => n).toString()
      );
      component.set('v.spinner', false);
    } else {
      component.set('v.msgTable', 'no');
      if (responseCall.simulation.simulationCalculated['Base Case'] && responseCall.simulation.simulationCalculated.Down && responseCall.simulation.simulationCalculated.Up) {
        this.getColumns(component);
      } else {
        component.set('v.calculatingRating', 'true');
        this.promiseStandAlone(component, responseCall.simulation.recordsNoCalculated)
          .then(function() {
            if (component.get('v.msgError') === 'null') {
              component.set('v.msgError', 'NoError');
            }
            component.set('v.spinner', false);
          })
          .catch(function(error) {
            component.set('v.spinner', false);
          });

      }
    }
  },
  calculateRating: function(cmp, recordToCalculate) {
    return new Promise($A.getCallback((resolve, reject) => {
      var action = cmp.get('c.callStandAlone');
      action.setParams({
        recordId: cmp.get('v.accHasAnalysisId'),
        projectionId: recordToCalculate
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var responseProjection = response.getReturnValue();
          resolve(responseProjection);
        } else {
          var errors = response.getError();
          reject(errors);
        }
      });
      $A.enqueueAction(action);
    }));
  },
  promiseStandAlone: function(cmp, recordToCalculate) {
    const promises = [];
    for (var i = 0; i < recordToCalculate.length; i++) {
      promises.push(this.calculateRating(cmp, recordToCalculate[i].Id));
    }
    return Promise.all(promises)
      .then(function(responses) {
        responses.forEach(function(element) {
          if (element.length !== 0) {
            cmp.set('v.msgError', JSON.stringify(element));
          }
        });
      })
      .catch(function(error) {
        cmp.set('v.msgError', error[0]);
      });
  },
  responseStandAlone: function(component, recordList, columns) {
    var projectionData = [];
    if (recordList.dataTable.length > 0) {
      recordList.dataTable.forEach(function(element, index) {
        if (element.arce__Scenario_Type__c === 'Base Case') {
          columns.push({
            label: element.arce__Projection_Header__c,
            fieldName: element.arce__Projection_Header__c,
            type: 'text',
            editable: false,
            wrapText: false,
          });
        }
        projectionData.push(element);
      });
      component.set('v.columns', columns);
      component.set('v.projectionData', projectionData);
      this.createTableStructure(component, projectionData, recordList);
    } else {
      component.set('v.msgError', 'Error: No records were found in Projection Process');
    }
  }
});