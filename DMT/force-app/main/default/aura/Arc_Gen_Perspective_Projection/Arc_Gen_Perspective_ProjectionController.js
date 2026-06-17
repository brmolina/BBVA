({
  initEng: function(component, event, helper) {
    component.set('v.spinner', true);
    helper.projectionCriteria(component, '1');
    helper.getBaseCaseScenarioData(component, null, helper);
    component.set('v.caseBaseOption', 'BaseCase'); 
    helper.setBannerSettings(component, event, helper);
  },
  loadData: function(component, event, helper) {
    helper.loadDataHelper(component, helper);
  },
  openModel: function(cmp, event, helper) {
    cmp.set('v.ffssErrorMsg', '');
    var accList = cmp.get('v.acctList');
    if (accList.length === 0) {
      cmp.set('v.spinnerInfinite', true);
      helper.financialList(cmp, helper);
      helper.setColumns(cmp);
    }
    cmp.set('v.isModalOpen', true);
  },
  closeModel: function(cmp, event, helper) {
    helper.closeModalHelper(cmp);
  },
  scenarioChange: function(cmp, event, helper) {
    cmp.set('v.spinner', true);
    var controlScenario = cmp.get('v.controlScenario');
    cmp.set('v.valueComment', '');
    if (controlScenario) {
      var changeValue = event.getParam('value');
      cmp.set('v.caseBaseOption', changeValue);
      helper.scenarioChangeHelper(cmp, event, changeValue, helper);
    } else {
      helper.toastMessage('WARNING', 'Base Case not calculated, you must calculate base case to access to scenarios');
      cmp.set('v.caseBaseOption', null);
      cmp.set('v.value', null);
      cmp.set('v.spinner', false);
    }

  },
  caseBaseOptions: function(cmp, event, helper) {
    var selectBaseCase = event.getParam('value');
    cmp.set('v.valueBaseCase', selectBaseCase);
    if (selectBaseCase === 'No') {
      helper.projectionCriteria(cmp, '1');
    } else {
      helper.projectionCriteria(cmp, '2');
    }
  },
  editScenario: function(cmp, event, helper) {
    cmp.set('v.spinner', true);
    var scenario = cmp.get('v.caseBaseOption') === 'BaseCase' ? 'Base Case' : cmp.get('v.caseBaseOption');
    var valuesEdited = cmp.get('v.setValuesEdited');
    var proCriteria =  cmp.get('v.criteriaValue');
    var editCase = cmp.get('v.valueBaseCase') === 'Yes' ? '1' : '2';

    helper.updateKeyAssumptions(cmp, valuesEdited, scenario, editCase, proCriteria)
      .then(function(result) {
        var mapValidation = new Map(Object.entries(result));
        var control = true;
        for (let [, value] of mapValidation) {
          if (value.length !== 0) {
            helper.manageValidationError(cmp, helper, value[0]);
            control = false;
          }
        }
        if (control) {
          helper.projectionEngineHelper(cmp, event, helper, true, scenario);
        } else {
          cmp.set('v.spinner', false);
        }
      })
      .catch(function(err) {
        cmp.set('v.spinner', false);
        helper.toastMessage('ERROR', ' Check Keyassumptions data and try again');
        helper.toastMessage('ERROR', +err[0].message);

      });
  },
  projectionCriteriaChange: function(cmp, event) {
    var criteria = cmp.find('projecCriteria').get('v.value');
    cmp.set('v.criteriaValue', criteria);
  },
  handleSaveEdition: function(cmp, event, helper) {
    var scenario = cmp.get('v.caseBaseOption');
    if (scenario === 'BaseCase') {
      cmp.set('v.disabledOptions', false);
    } else if (scenario === 'Up') {
      cmp.set('v.disabledOptionsUp', false);
    } else if (scenario === 'Down') {
      cmp.set('v.disabledOptionsDown', false);
    }

    var draftValues = event.getParam('draftValues');
    helper.manageEdit(cmp, draftValues, helper);
    cmp.set('v.valueBaseCase', 'Yes');
    helper.projectionCriteria(cmp, '2');

  },
  projectionEngine: function(cmp, event, helper, isEdition) {
    var scenario = 'Base Case';
    helper.projectionEngineHelper(cmp, event, helper, isEdition, scenario);
  },
  checkValiditySelection: function(cmp, event, helper) {
    var selec = cmp.get('v.anchorEEFF');
    var selectedRows = event.getParam('selectedRows');
    var selectedIds = [];
    var preval = cmp.get('v.preValues');
    var preValue = [];

    let map = new Map();
    var preEEFFselected = false;
    selectedRows.forEach(function(element) {
      if (element.arce__financial_statement_id__c === selec[0]) {
        preEEFFselected = true;
      }
      selectedIds.push(element.arce__financial_statement_id__c);
      map.set(element.arce__financial_statement_id__c, element.arce__financial_statement_end_date__c);
    });
    cmp.set('v.selectedRows', selectedIds);
    if (preval.length === 0) {
      preValue.push(selec[0]);

    } else {
      preValue = preval;
    }

    if (preEEFFselected) {
      let difference = selectedIds.filter(x => !preValue.includes(x));
      helper.sameYearSelection(cmp, event, selectedRows, difference, selectedIds, map, helper);

    } else {
      selectedIds.push(selec[0]);
      helper.toastMessage('WARNING', 'Warning: You can not uncheck the anchor');
      cmp.set('v.selectedRows', Object.values(selectedIds));
    }
  },
  printTable: function(cmp, event, helper) {
    window.open('/apex/arce__Arc_Gen_PDF_Projection_DataTable_Summary' + '?ahaId=' +    cmp.get('v.accHasAnalysisId'));
  },
  saveComment: function(cmp, event, helper) {
    var action = cmp.get('c.updateScenarioComment');
    action.setParams({
      recordId: cmp.get('v.accHasAnalysisId'),
      scenario: cmp.get('v.caseBaseOption') === 'BaseCase' ? 'Base Case' : cmp.get('v.caseBaseOption'),
      scenarioComment: cmp.get('v.valueComment'),
      proposalId: cmp.get('v.proposalFolderId') !== '!proposalFolderId' ? cmp.get('v.proposalFolderId') : null  
    }); 
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        helper.toastMessage('SUCCESS', 'Success :  Comment saved successfully');
      } else {
        helper.toastMessage('ERROR', 'An error has ocurred saving the comment');
      }
    });
    $A.enqueueAction(action);
  }
});