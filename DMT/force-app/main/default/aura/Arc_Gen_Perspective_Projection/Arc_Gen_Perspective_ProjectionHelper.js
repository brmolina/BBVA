({
  financialList: function(cmp, helper) { 
    var action = cmp.get('c.fetchFinancialStatements');
    action.setParams({
      varRecord: cmp.get('v.accHasAnalysisId'),
      isFinancialRAIP: true,
      isRAIP: false,
      ratingToolSelect: null,
      requestedPage: cmp.get('v.currentPage'),
    });

    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var responseFFSS = response.getReturnValue();
        helper.setupPaginationFFSS(cmp, responseFFSS);
        helper.setValuesFFSS(cmp, helper, responseFFSS);
      } else if (state === 'ERROR') {
        var errorsffss = response.getError();
        let errorffssMsg;

        if (errorsffss[0] && errorsffss[0].message) {
          errorffssMsg = errorsffss[0].message;
        } else {
          errorffssMsg = 'Error: An unexpected error has ocurred, please try again later';
        }

        cmp.set('v.ffssErrorMsg', errorffssMsg);
        cmp.set('v.spinnerInfinite', false);
      }
    });
    $A.enqueueAction(action);
  },
  setupPaginationFFSS: function(cmp, responseFFSS) {
    if (responseFFSS.pagination !== undefined) {
      var pagefss = responseFFSS.pagination.page;
      var totalPagesffss = responseFFSS.pagination.totalPages;
      if (pagefss >= totalPagesffss) {
        cmp.set('v.infiniteFFSS', false);
      }
    } else {
      cmp.set('v.infiniteFFSS', false);
    }
  },
  setValuesFFSS: function(component, helper, responseWrapper) {
    var ffssListLabel = helper.formatId(responseWrapper.ffssListLabel);
    var fssselected = responseWrapper.preselected;
    var acctList = component.get('v.acctList');
    var ffssList = component.get('v.ffssList');
    var date;
    var  adjustment;
    var type;
    var currency;
    var preSelectedRows = [];
    if (
      component.get('v.dateFFSS') === undefined ||
      component.get('v.adjustmentFFSS') === undefined ||
      component.get('v.typeFFSS') === undefined
    ) {
      ffssListLabel.forEach(function(element) {
        if (element.arce__financial_statement_id__c === fssselected[0]) {
          component.set('v.eeffData', element);
          date = element.arce__financial_statement_end_date__c;
          component.set('v.dateFFSS', date);
          type = element.arce__ffss_submitted_type__c;
          component.set('v.typeFFSS', type);
          adjustment = element.arce__ffss_adjusted_type__c;
          component.set('v.adjustmentFFSS', adjustment);
          currency = element.CurrencyIsoCode;
          component.set('v.currency', currency);
          preSelectedRows.push(element.arce__financial_statement_id__c);
          component.set('v.selectedRows', preSelectedRows);
          component.set('v.anchorEEFF', fssselected);
        }
      });
    } else {
      date = component.get('v.dateFFSS');
      type = component.get('v.typeFFSS');
      adjustment = component.get('v.adjustmentFFSS');
      currency = component.get('v.currency');
    }
    ffssListLabel.forEach(function(element) {
      if (
        element.arce__economic_month_info_number__c === '12' &&
        element.arce__ffss_submitted_type__c === type &&
        element.CurrencyIsoCode === currency &&
        (String(element.arce__financial_statement_end_date__c.slice(0, 4)) === String(date.slice(0, 4) - 1) ||
        String(element.arce__financial_statement_end_date__c.slice(0, 4)) === String(date.slice(0, 4) - 2) ||
        String(element.arce__financial_statement_end_date__c.slice(0, 4)) === String(date.slice(0, 4)))
      ) {
        acctList.push(element);
      }
    });
    responseWrapper.ffssList.forEach(function(element) {
      ffssList.push(element);
    });
    helper.setModalMessage(component, acctList, ffssList, responseWrapper, helper);
  },
  setColumns: function(component) {
    var action = component.get('c.getDynamicColumns');
    action.setParams({
      isRating: false
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var columns = JSON.parse(response.getReturnValue());
        component.set('v.mycolumns', columns);
      } else {
        component.set('v.mycolumns', columns);
      }
    });
    $A.enqueueAction(action);
  },
  toastMessage: function(status, message) {
    switch (status) {
      case 'SUCCESS':
        var toastSuccess = $A.get('e.force:showToast');
        toastSuccess.setParams({
          'title': 'Success!',
          'type': 'success',
          'mode': 'sticky',
          'duration': '8000',
          'message': message
        });
        toastSuccess.fire();
        break;
      case 'ERROR':
        var toastError = $A.get('e.force:showToast');
        toastError.setParams({
          'title': 'Error!',
          'type': 'error',
          'mode': 'sticky',
          'duration': '8000',
          'message': 'Error: ' + message
        });
        toastError.fire();
        break;
      case 'WARNING':
        var toastWarning = $A.get('e.force:showToast');
        toastWarning.setParams({
          'title': 'Warning!',
          'type': 'warning',
          'mode': 'sticky',
          'duration': '8000',
          'message': message
        });
        toastWarning.fire();
        break;
      case 'INFO':
        var toastInfo = $A.get('e.force:showToast');
        toastInfo.setParams({
          'title': 'Info!',
          'type': 'info',
          'mode': 'sticky',
          'duration': '8000',
          'message': message
        });
        toastInfo.fire();
        break;
    }
  },
  formatId: function(ffsstoFormat) {
    ffsstoFormat.map((element) => {
      element.shortId = element.arce__financial_statement_id__c.replace(/^0+/, '');
    });
    return ffsstoFormat;
  },
  getBaseCaseScenarioData: function(cmp, scenario, helper) {
    const mapUnits = {'1': 'Units', '2': 'Thousands', '3': 'Millions', '4': 'Billions'};
    cmp.set('v.simulationButton', false);
    var action = cmp.get('c.getScenarioData');
    action.setParams({
      recordId: cmp.get('v.accHasAnalysisId'),
      scenario: scenario,
      isSimulation: false,
      proposalId: (cmp.get('v.proposalFolderId') !== '!proposalFolderId' && cmp.get('v.proposalFolderId') !== undefined) ? cmp.get('v.proposalFolderId') : null
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var responseCall = response.getReturnValue();
        if (responseCall.ahaData === '3' && (cmp.get('v.proposalFolderId') === '!proposalFolderId' || cmp.get('v.proposalFolderId') === undefined) && cmp.get('v.checkAhaStatus')) {
          cmp.set(
            'v.ahaStageFin',
            true
          );
        }
        cmp.set(
          'v.currency',
          responseCall.financialStatementRecord.CurrencyIsoCode
        );
        cmp.set(
          'v.valueUnits',
          '3'
        );
        cmp.set(
          'v.valueUnitsReal',
          responseCall.financialStatementRecord.arce__magnitude_unit_type__c
        );
        cmp.set(
          'v.literalUnits',
          mapUnits[cmp.get(
            'v.valueUnits')]
        );
        if (responseCall.dataTable.length === 0) {
          cmp.set('v.controlScenario', false);
          cmp.set('v.projectionCalculated', 'No');
        } else {
          this.reduceComplexity(cmp, helper, scenario, responseCall);
        }
        cmp.set('v.spinner', false);
        cmp.set('v.spinnerInfinite', false);
      } else {
        //Error
        cmp.set('v.spinner', false);
        helper.toastMessage(
          'ERROR',
          'Error trying to populate tables'
        );

      }
    });
    $A.enqueueAction(action);
  },
  createTableColumStructure: function(cmp, response) {
    var columns = [];
    var columnsKey = [];
    columns.push({
      label: 'Name',
      fieldName: 0,
      type: 'text',
      editable: false,
    });

    columnsKey.push({
      label: 'Name',
      fieldName: 0,
      type: 'text',
      editable: false,
    });
    response.dataTable.forEach(function(element, index) {
      columns.push({
        label: element.arce__Projection_Header__c,
        fieldName: element.Id,
        type: 'number',
        editable: false,
        cellAttributes: { alignment: 'left' }
      });
      columns.push({
        label: '',
        fieldName: '%' + element.Id,
        type: 'text',
        editable: false,
        initialWidth: 100,
        cellAttributes: { alignment: 'center' },
      });
      columnsKey.push({
        label: element.arce__Projection_Header__c,
        fieldName: element.Id,
        type: 'number',
        editable: false,
        cellAttributes: { alignment: 'left' },
      });
    });
    cmp.set('v.columns', columns);
    cmp.set('v.columnsKey', columnsKey);
  },
  fillTables: function(cmp, firstKey, projectionData, data, percentage, helper, isCapex) {
    const mapformatPer = cmp.get('v.mapformatPer');
    var sizeData = data.length;
    if (projectionData.length !== 0) {
      projectionData.forEach(function(element, index) {
        const map2 = new Map(Object.entries(element));

        var valueCalc = map2.get(firstKey);
        if (mapformatPer.get(firstKey)) {
          valueCalc = valueCalc * 100;
        }
        data[sizeData - 1][element.Id] = valueCalc === undefined ? '--' : valueCalc;
        data[sizeData - 1]['%' + element.Id] = map2.get(percentage) === undefined ? '' : +map2.get(percentage) + ' %';
      });
    }
  },
  scenarioChangeHelper: function(cmp, event, changeValue, helper) {
    if (changeValue === 'BaseCase') {
      this.getBaseCaseScenarioData(cmp, 'Base Case', helper);
      if (cmp.get('v.valueBaseCase') === 'Yes') {
        cmp.set('v.simulationButton', true);
      }
    } else if (changeValue === 'Up') {
      this.getBaseCaseScenarioData(cmp, changeValue, helper);
      cmp.set('v.scenarioSimulation', 'Up Scenario Simulation');
    } else if (changeValue === 'Down') {
      this.getBaseCaseScenarioData(cmp, changeValue, helper);
      cmp.set('v.scenarioSimulation', 'Down Scenario Simulation');
    }
    cmp.set('v.setValuesEdited', {});
  },
  updateKeyAssumptions: function(cmp, valuesEdited, scenario, editCase, proCriteria) {
    var unitsReal = cmp.get('v.valueUnitsReal');

    return new Promise($A.getCallback((resolve, reject) => {
      scenario = scenario === 'BaseCase' ? 'Base Case' : scenario;
      var action = cmp.get('c.updateKeyAssumptions');
      action.setParams({
        editedValues: JSON.stringify(valuesEdited),
        scenario: scenario,
        editCase: editCase,
        projectionCriteria: proCriteria,
        ahaId: cmp.get('v.accHasAnalysisId'),
        unitsReal: unitsReal,
        proposalId: (cmp.get('v.proposalFolderId') !== '!proposalFolderId' && cmp.get('v.proposalFolderId') !== undefined) ? cmp.get('v.proposalFolderId') : null
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        var responseUpdate = response.getReturnValue();
        if (state === 'SUCCESS') {
          resolve(responseUpdate);
        } else {
          var errors = response.getError();
          reject(errors);
        }
      });
      $A.enqueueAction(action);
    }));
  },
  projectionCriteria: function(component, type) {
    var optsCriteria = [];
    var disabledCriteria;
    var criteriaValue = component.get('v.criteriaValue');
    var simulationButton;
    var valueBaseCase;

    switch (type) {
      case '1':
        optsCriteria = [
          { value: 'Standard projection', label: 'Standard projection' },
        ];
        disabledCriteria = true;
        simulationButton = false;
        valueBaseCase = 'No';

        break;

      case '2':
        optsCriteria = [
          { value: 'Business plan', label: 'Business plan' },
          { value: 'Market consensus', label: 'Market consensus' },
          { value: 'Expert judgment', label: 'Expert judgment' },
        ];
        disabledCriteria = false;
        simulationButton = true;
        valueBaseCase = 'Yes';
        if (criteriaValue === 'Standard projection') {
          component.set('v.criteriaValue', 'Business plan');
        } else {
          component.set('v.criteriaValue', criteriaValue);
        }
        break;
    }
    component.set('v.projecCriteria', optsCriteria);
    component.set('v.disabledCriteria', disabledCriteria);
    component.set('v.simulationButton', simulationButton);
    component.set('v.valueBaseCase', valueBaseCase);
  },
  sameYearSelection: function(cmp, event, selectedRows, difference, selectedIds, map, helper) {
    if (difference.length > 0) {
      selectedRows.forEach(function(element) {
        if (
          element.arce__financial_statement_end_date__c.slice(0, 4) ===
            map.get(difference[0]).slice(0, 4) &&
          element.arce__financial_statement_id__c !== difference[0]
        ) {
          const index = selectedIds.indexOf(difference[0]);

          if (index > -1) {
            selectedIds.splice(index, 1);
          }
          cmp.set('v.preValues', selectedIds);
          cmp.set('v.selectedRows', selectedIds);
          helper.toastMessage(
            'WARNING',
            'You have already selected a financial statement with that date'
          );
        } else {
          cmp.set('v.preValues', selectedIds);
          cmp.set('v.selectedRows', selectedIds);
        }
      });
    }
  },
  manageResponse: function(cmp, response, helper, mapLabelAPI, mapOrder, mapPercentageValue) {
    var firstKey = [];
    var firstValue = [];
    var dataBalance = [];
    var dataKey = [];
    var data1 = [];
    var data2 = [];
    var data3 = [];

    for (let [key, value] of mapLabelAPI) {
      var controlMapValue = new Map(Object.entries(value));
      var tableOrder = mapOrder.get(key);
      if (tableOrder === '1') {
        this.setTableOrder(cmp, tableOrder);
        [ firstKey ] = controlMapValue.keys();
        [ firstValue ] = controlMapValue.values();
        dataBalance.push({ 0: firstValue });
        this.fillTables(
          cmp,
          firstKey,
          response.dataTable,
          dataBalance,
          mapPercentageValue.get(firstKey),
          helper,
          firstValue
        );
      } else if (tableOrder === '2') {
        this.setTableOrder(cmp, tableOrder);
        [ firstKey ] = controlMapValue.keys();
        [ firstValue ] = controlMapValue.values();
        data1.push({ id: firstKey, 0: firstValue });
        this.fillTables(cmp, firstKey, response.dataTable, data1, mapPercentageValue.get(firstKey), helper, firstValue);
      } else if (tableOrder === '3') {
        this.setTableOrder(cmp, tableOrder);
        [ firstKey ] = controlMapValue.keys();
        [ firstValue ] = controlMapValue.values();
        data2.push({ id: firstKey, 0: firstValue });
        this.fillTables(cmp, firstKey, response.dataTable, data2, mapPercentageValue.get(firstKey), helper, firstValue);
      } else if (tableOrder === '4') {
        this.setTableOrder(cmp, tableOrder);
        [ firstKey ] = controlMapValue.keys();
        [ firstValue ] = controlMapValue.values();
        data3.push({ id: firstKey, 0: firstValue });
        this.fillTables(cmp, firstKey, response.dataTable, data3, mapPercentageValue.get(firstKey), helper, firstValue);
      } else if (tableOrder === '5') {
        this.setTableOrder(cmp, tableOrder);
        [ firstKey ] = controlMapValue.keys();
        [ firstValue ] = controlMapValue.values();
        dataKey.push({ id: firstKey, 0: firstValue });
        this.fillTables(cmp, firstKey, response.dataTable, dataKey, mapPercentageValue.get(firstKey), helper, firstValue);
      }
    }
    this.variableAssignment(cmp, dataBalance, data1, data2, data3, dataKey);
  },
  manageEdit: function(cmp, draftValues, helper) {
    var mapChanges = cmp.get('v.setValuesEdited');
    const mapForPer = cmp.get('v.mapformatPer');
    var listIds = mapChanges === null ? '' : Object.keys(mapChanges);
    var projectionId;
    draftValues.forEach(function(element) {
      var listIds2 = Object.keys(element);
      listIds2.forEach(function(element2) {
        if (element2 !== 'id') {
          projectionId = element2;
        }
      });
      var APIname = element.id;
      var value = !element[projectionId] ? 0 : element[projectionId];
      if (mapForPer.get(APIname)) {
        value = value / 100;
      }
      if (!isNaN(value)) {
        if (listIds.includes(projectionId)) {
          var mapApiValue = mapChanges[projectionId];
          mapApiValue[APIname] = value;
          mapChanges[projectionId] = mapApiValue;
        } else {
          const mapApiNewValue = new Map();
          mapApiNewValue[APIname] = value;
          mapChanges[projectionId] = mapApiNewValue;
        }
      } else {
        helper.toastMessage(
          'ERROR',
          'Error in data: Check key assumptions values'
        );
      }
    });
    cmp.set('v.setValuesEdited', mapChanges);
  },
  setControlValues: function(cmp, scenario, control, helper) {
    var action = cmp.get('c.updateControlValues');
    action.setParams({
      recordId: cmp.get('v.accHasAnalysisId'),
      scenario: scenario,
      controlValue: control,
      proposalId: (cmp.get('v.proposalFolderId') !== '!proposalFolderId' && cmp.get('v.proposalFolderId') !== undefined) ? cmp.get('v.proposalFolderId') : null
    });

    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'ERROR') {
        helper.toastMessage(
          'ERROR',
          'Error : Control values have not been updated'
        );
      }
    });

    $A.enqueueAction(action);
  },
  checkControlValues: function(cmp, scenario, responseWrapper) {
    scenario = scenario  === null ? 'Base Case' : scenario;
    if (responseWrapper.controlValues === false && scenario === 'Base Case') {
      this.projectionCriteria(cmp, '1');
    } else {
      if (scenario === 'Base Case') {
        cmp.set('v.disabledOptions', false);
        cmp.set(
          'v.valueBaseCase',
          responseWrapper.editBaseCase === '1' ? 'Yes' : 'No'
        );
        responseWrapper.projectionCriteria === 'Standard projection'
          ? this.projectionCriteria(cmp, '1')
          : this.projectionCriteria(cmp, '2');
        cmp.set('v.criteriaValue', responseWrapper.projectionCriteria);
      }
      cmp.set('v.disabledOptions', responseWrapper.controlValues['Base Case']);
      cmp.set('v.disabledOptionsUp', responseWrapper.controlValues.Up);
      cmp.set('v.disabledOptionsDown', responseWrapper.controlValues.Down);
    }
    cmp.set('v.spinner', false);
  },
  cleanControlValues: function(cmp) {
    cmp.set('v.disabledOptions', false);
    cmp.set('v.disabledOptionsUp', false);
    cmp.set('v.disabledOptionsDown', false);
    cmp.set('v.valueBaseCase', 'No');
    cmp.set('v.criteriaValue', 'Standard projection');
    cmp.set('v.disabledCriteria', true);
  },
  setDisabledOptions: function(cmp, scenario, helper) {
    if (scenario === 'Base Case') {
      cmp.set('v.disabledOptions', true);
    } else if (scenario === 'Up') {
      cmp.set('v.disabledOptionsUp', true);
      cmp.set('v.disabledOptions', true);
    } else if (scenario === 'Down') {
      cmp.set('v.disabledOptionsDown', true);
      cmp.set('v.disabledOptions', true);
    }
    this.messageWarning(cmp, helper);
  },
  messageWarning: function(cmp, helper) {
    var warningMessage = [];
    if (cmp.get('v.disabledOptions') === false) {
      warningMessage.push('Base Case');
    }
    if (cmp.get('v.disabledOptionsDown') === false) {
      warningMessage.push('Down');
    }
    if (cmp.get('v.disabledOptionsUp') === false) {
      warningMessage.push('Up');
    }
    if (warningMessage.length > 0) {
      helper.toastMessage(
        'INFO',
        'Info : You should edit ' + warningMessage
      );
    }
  },
  setWay: function(cmp, event, isEdition, scenario, helper) {
    if (isEdition) {
      this.getBaseCaseScenarioData(cmp, scenario, helper);
    } else {
      this.getBaseCaseScenarioData(cmp, null, helper);
      cmp.set('v.caseBaseOption', 'BaseCase');
      cmp.set('v.controlScenario', true);
      this.scenarioChangeHelper(cmp, event, 'BaseCase', helper);
      this.cleanControlValues(cmp);
    }
  },
  projectionEngineHelper: function(cmp, event, helper, isEdition, scenario) {
    var selectedEEFF = cmp.get('v.selectedRows');
    cmp.set('v.spinner', true);
    cmp.set('v.spinnerInfinite', true);
    var action = cmp.get('c.callProjectionService');
    action.setParams({
      scenarioType: scenario,
      ahaId: cmp.get('v.accHasAnalysisId'),
      financialStatemIds: isEdition ? null : Object.values(selectedEEFF),
      proposalId: (cmp.get('v.proposalFolderId') !== '!proposalFolderId' && cmp.get('v.proposalFolderId') !== undefined) ? cmp.get('v.proposalFolderId') : null
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      cmp.set('v.spinner', true);
      if (state === 'SUCCESS') {
        var responseProjection = response.getReturnValue();
        if (responseProjection.length === 0) {
          this.checkEventFire(cmp, event, helper, scenario, isEdition);
          cmp.set('v.msgTable', 'si');
        } else {
          helper.toastMessage('ERROR', responseProjection[0]);
          cmp.set('v.spinnerInfinite', false);
          cmp.set('v.spinner', false);
          this.setControlValues(cmp, scenario, false, helper);
        }
      } else {
        helper.toastMessage('ERROR', 'An error has ocurred, please try again later: ' + response.getError()[0].message);
        cmp.set('v.spinnerInfinite', false);
        cmp.set('v.spinner', false);
        this.setControlValues(cmp, scenario, false, helper);
      }
    });
    $A.enqueueAction(action);
  },
  variableAssignment: function(cmp, dataBalance, data1, data2, data3, dataKey) {
    var gridDataBalance = [];
    var collapsibleData = [];
    var gridDataPL = [];
    var gridDataCF = [];
    var gridDataKR = [];
    gridDataBalance.push('Balance sheet');
    gridDataBalance._children = dataBalance;
    collapsibleData.push(gridDataBalance);
    gridDataPL.push('P&L');
    gridDataPL._children  = data1;
    collapsibleData.push(gridDataPL);
    gridDataCF.push('CASH FLOW');
    gridDataCF._children  = data2;
    collapsibleData.push(gridDataCF);
    gridDataKR.push('Key Ratios');
    gridDataKR._children  = data3;
    collapsibleData.push(gridDataKR);
    cmp.set('v.gridData', collapsibleData);
    cmp.set('v.dataKey', dataKey);
    var expandedRows = ['Balance sheet', 'P&L', 'CASH FLOW', 'Key Ratios'];
    cmp.set('v.gridExpandedRows', expandedRows);
  }, 
  setTableOrder: function(cmp, value) {
    cmp.set('v.tableOrder', value);
  },
  manageValidationError: function(cmp, helper, value) {
    switch (value) {
      case 'Arc_Days_Rule':
        helper.toastMessage('ERROR', 'Validation Error: The days cannot be negative');
        break;
      case 'Arc_Ebitda_Margin_Rule':
        helper.toastMessage('ERROR', 'Validation Error: EBITDA Margin (%) -> Values between [-100,100] ');
        break;
      case 'Arc_PayOut_Rule':
        helper.toastMessage('ERROR', 'Validation Error: Pay-out (%) -> Values between [0,100] ');
        break;
      case 'Arc_Revenue_Rule':
        helper.toastMessage('ERROR', 'Revenue Growth (%) -> Values between [-100,∞] ');
        break;
      case 'Arc_Gen_Interest_Gross':
        helper.toastMessage('ERROR', 'Interest expenses / Gross debt (%) -> Values between [0,100] ');
        break;
    }
  },
  setModalMessage: function(component, acctList, ffssList, resposeFFSS, helper) {
    var selected = component.get('v.selectedRows');
    if (resposeFFSS.pagination !== undefined) {
      var pagefss = resposeFFSS.pagination.page;
      var totalPagesffss = resposeFFSS.pagination.totalPages;
      if (pagefss >= totalPagesffss) {
        var selectedFinal = [];
        acctList.forEach(function(element) {
          if (element.arce__financial_statement_id__c === selected[0]) {
            selectedFinal.push(element.arce__financial_statement_id__c);
          }

        });
        if (ffssList.length === 0) {
          component.set('v.ffssErrorMsg', 'Unable to display financial statements due to filters ');
        }
        component.set('v.acctList', acctList);
        component.set('v.ffssList', ffssList);
        component.set('v.spinnerInfinite', false);
        component.set('v.infiniteFFSS', false);
        component.set('v.selectedRows', selectedFinal);
      } else {
        component.set('v.spinnerInfinite', true);
        component.set('v.infiniteFFSS', true);
        helper.loadDataHelper(component, helper);
      }
    }
  },
  closeModalHelper: function(cmp, event, helper) {
    cmp.set('v.isModalOpen', false);
    cmp.set('v.msgTable', '');
    cmp.set('v.ffssErrorMsg', '');
  },
  tableOrderDefinition: function(tableOrder, value, div, isCapex) {
    if (value !== undefined && (tableOrder === '1' || tableOrder === '2' || tableOrder === '3' || isCapex === 'Capex')) {
      value = Math.trunc(Number(value / div));
    } else if (value !== undefined && tableOrder === '4') {
      value = Math.trunc(value * Math.pow(10, 2)) / Math.pow(10, 2);
    }
    return value;
  },
  setBannerSettings: function(cmp, event, helper) {
    cmp.set('v.bannerMessage', $A.get('{!$Label.c.Arc_Gen_ProjectionBannerMessage}'));
    var action = cmp.get('c.getAhaObject');
    action.setParams({
      recordId: cmp.get('v.recordId')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var ahaRecord = response.getReturnValue();

        //set visibility conditions here
        if (ahaRecord.arce__ffss_for_rating_id__r.arce__economic_month_info_number__c < 12) {
          cmp.set('v.isBannerEnabled', true);
        }
      } else {
        helper.toastMessage('ERROR', response.getError()[0].message);
      }
    });
    $A.enqueueAction(action);
  },
  recalculateUnits: function(cmp, event, helper) {
    var action = cmp.get('c.recalculateUnits');
    action.setParams({
      ahaId: cmp.get('v.recordId')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        helper.refreshTables(cmp, helper);
      } else {
        helper.toastMessage('ERROR', response.getError()[0].message);
      }
    });
    $A.enqueueAction(action);
  },
  recalculateCurrency: function(cmp, event, helper) {
    var action = cmp.get('c.recalculateCurrency');
    action.setParams({
      ahaId: cmp.get('v.recordId')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        helper.refreshTables(cmp, helper);
      } else {
        helper.toastMessage('ERROR', response.getError()[0].message);
      }
    });
    $A.enqueueAction(action);
  },  
  refreshTables: function(cmp, helper) {
    var action = cmp.get('c.initEng');
    $A.enqueueAction(action);
  },
  cloneProjection: function(component, event, helper) {
    return new Promise((resolve, reject) => {
      var action = component.get('c.callCloneProjection');
      action.setParams({
        scenarioType: 'CLONE',
        ahaId: component.get('v.accHasAnalysisId'),
        proposalId: (component.get('v.proposalFolderId') !== '!proposalFolderId' && component.get('v.proposalFolderId') !== undefined) ? component.get('v.proposalFolderId') : null
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        var responseProjection = response.getReturnValue();
        if (state === 'SUCCESS') {
          if (responseProjection.length > 0) {
            helper.toastMessage('ERROR', 'ERROR : Error cloning projections' + responseProjection[0]);
            reject();
          } else {
            helper.toastMessage('SUCCESS', 'Success : Scenario have been Cloned successfully');
            resolve();
          }
        } else {
          helper.toastMessage('ERROR', 'Error : An error has ocurred in the controlling class');
          reject();
        }
      });
      $A.enqueueAction(action);
    });
  },
  reduceComplexity: function(cmp, helper, scenario, responseCall) {
    var colunmsEditables = [];
    if ((cmp.get('v.proposalFolderId') !== '!proposalFolderId' && cmp.get('v.proposalFolderId') !== undefined) && responseCall.controlClone === true) {
      cmp.set('v.spinnerClone', true);
      this.cloneProjection(cmp, scenario, helper)
        .then(function() {
          cmp.set('v.spinnerClone', false);
          helper.refreshTables(cmp, helper);
        })
        .catch(function() {
          cmp.set('v.spinnerClone', false);
        });
    } else {
      cmp.set('v.spinnerClone', false);
    }
    cmp.set('v.controlScenario', true);
    cmp.set('v.projectionCalculated', 'Yes');
    this.createTableColumStructure(cmp, responseCall);
    var mapLabelAPI = new Map(Object.entries(responseCall.mapLabelAPI));
    var mapOrder = new Map(Object.entries(responseCall.valuesMappingTableOrder));
    var mapFormatPer = new Map(Object.entries(responseCall.mapAPIFormatPer));
    cmp.set('v.mapformatPer', mapFormatPer);
    var mapPercentageValue = new Map(
      Object.entries(responseCall.mapIdFieldPercentage)
    );
    this.manageResponse(cmp, responseCall, helper, mapLabelAPI, mapOrder, mapPercentageValue);
    this.checkControlValues(cmp, scenario, responseCall.controlChecking);

    colunmsEditables = cmp.get('v.columnsKey');
    colunmsEditables.forEach(function(element, index) {
      if (colunmsEditables.indexOf(element) > 1
          && ((responseCall.ahaData !== '3' &&  (cmp.get('v.proposalFolderId') === '!proposalFolderId' || cmp.get('v.proposalFolderId') === undefined))
          || (responseCall.ahaData === '3' &&  (cmp.get('v.proposalFolderId') !== '!proposalFolderId' && cmp.get('v.proposalFolderId') !== undefined)))) {
        element.editable = true;
      }
    });
    cmp.set('v.columnsKey', colunmsEditables);
    cmp.set('v.valueComment', responseCall.scenarioComment);
  },
  checkEventFire: function(cmp, event, helper, scenario, isEdition) {
    cmp.set('v.msgTable', 'si');
    window.setTimeout($A.getCallback(function() {
      helper.closeModalHelper(cmp);
    }), 2500);
    this.setDisabledOptions(cmp, scenario, helper);
    if (isEdition) {
      this.setControlValues(cmp, scenario, true, helper);
      cmp.set('v.msgTable', '');
    }
    this.setWay(cmp, event, isEdition, scenario, helper);
    helper.toastMessage('SUCCESS', 'Success : Scenario have been edited successfully');
    if (cmp.get('v.proposalFolderId') === '!proposalFolderId' || cmp.get('v.proposalFolderId') === undefined) {
      helper.recalculateUnits(cmp, event, helper);
      helper.recalculateCurrency(cmp, event, helper);
    }
  },
  loadDataHelper: function(component, helper) {
    component.set('v.spinnerInfinite', true);
    var currentPageffss = component.get('v.currentPage');
    var nextPageffss = currentPageffss + 1;
    component.set('v.currentPage', nextPageffss);
    helper.financialList(component, helper);
  }
});