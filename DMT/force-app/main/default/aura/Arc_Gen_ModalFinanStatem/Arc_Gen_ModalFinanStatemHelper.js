({
  fetchFinancialStatements: function(component, event, helper) {
    var action = component.get('c.fetchFinancialStatements');
    action.setParams({
      varRecord: component.get('v.accHasAnalysisId'),
      isFinancialRAIP: component.get('v.isFinancialRAIP'),
      isRAIP: component.get('v.isRAIP'),
      ratingToolSelect: component.get('v.ratingToolSelect'),
      requestedPage: component.get('v.currentPage')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var responseWrapper = response.getReturnValue();
        if (component.get('v.isFinancialRAIP')) {
          helper.setPreselected(component, event, helper, responseWrapper);
        }
        if (component.get('v.isRTC')) {
          helper.setPreselectedRTC(component, event, helper, responseWrapper);
        }
        helper.setupPagination(component, responseWrapper);
        helper.setValues(component, helper, responseWrapper);
      } else if (state === 'ERROR') {
        var errors = response.getError();
        let errorMsg;

        if (errors[0] && errors[0].message) {
          let toSplit = errors[0].message;
          let baseStr = 'Arc_Gen_ffss';
          let errorCode = toSplit.split('-')[0].trim();
          let labelSubStr = baseStr.concat(errorCode);
          if ($A.get('{!$Label.c.' + labelSubStr + '}') === '') {
            errorMsg = $A.get('{!$Label.c.Cls_arce_GRP_servError}');
          } else {
            errorMsg = $A.get('{!$Label.c.' + labelSubStr + '}');
          }

        } else {
          errorMsg = $A.get('{!$Label.c.Cls_arce_GRP_servError}');
        }

        component.set('v.ffssErrorMsg', errorMsg);
      }
      component.set('v.spinnerLoading', false);
    });
    $A.enqueueAction(action);
  },
  setupPagination: function(component, responseWrapper) {
    if (responseWrapper.pagination !== undefined) {
      var page = responseWrapper.pagination.page;
      var totalPages = responseWrapper.pagination.totalPages;
      if (page >= totalPages) {
        component.set('v.enableInfiniteLoading', false);
      }
    } else {
      component.set('v.enableInfiniteLoading', false);
    }
  },
  setValues: function(component, helper, responseWrapper) {
    var selectedFinal = [];
    var anchorFFSS = component.get('v.anchorEEFF') === undefined ? [] : component.get('v.anchorEEFF');
    var selectedsEEFF = component.get('v.selectedRows').length > 0 ? component.get('v.selectedRows') : anchorFFSS;
    var ffssListLabel = helper.removeZeroFFSSId(responseWrapper.ffssListLabel);
    var acctList = component.get('v.acctList');
    var ffssList = component.get('v.ffssList');

    ffssListLabel.forEach(function(element) {
      acctList.push(element);
    });
    responseWrapper.ffssList.forEach(function(element) {
      ffssList.push(element);
    });
    acctList.forEach(function(element) {
      if (element.arce__financial_statement_id__c === anchorFFSS) {
        selectedFinal.push(element.arce__financial_statement_id__c);
      }
    });
    component.set('v.preSelectedRows', selectedsEEFF);
    component.set('v.selectedRows2', selectedsEEFF);
    component.set('v.selectedRows', selectedsEEFF);
    component.set('v.elementsEEFF', selectedsEEFF);
    component.set('v.acctList', acctList);
    component.set('v.ffssList', ffssList);
    component.set('v.validLabel', responseWrapper.validLabel);
  },
  setColumns: function(component) {
    var action = component.get('c.getDynamicColumns');
    action.setParams({
      isRaip: component.get('v.isRAIP')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var columns = JSON.parse(response.getReturnValue());
        component.set('v.mycolumns', columns);
      }
    });
    $A.enqueueAction(action);
  },
  consultEngine: function(component, event, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var listIDS = component.get('v.selectedRows2');
      var eeffList = component.get('v.acctList');
      var msg = '';
      var errorMsg = '';
      let errorMessage;
      component.set('v.msgTable', msg);
      component.set('v.errorMsgTable', errorMsg);
      component.set('v.spinnerLoading', true);
      if (eeffList.length > 0 && listIDS.length > 0 && !component.get('v.isRTCnoFFSS')) {
        var action = component.get('c.callEngineFinancialState');
        action.setParams({
          recordId: component.get('v.accHasAnalysisId'),
          updatedEEFF: eeffList,
          financialIdList: listIDS,
          isRAIP: component.get('v.isRAIP'),
          isFinancialRAIP: component.get('v.isFinancialRAIP'),
          ratingToolSelect: component.get('v.ratingToolSelect'),
          pFolderArceId: component.get('v.proposalFolderArceId')
        });
        action.setCallback(this, function(response) {
          var state = response.getState();
          if (state === 'SUCCESS') {
            var resp = response.getReturnValue();
            if (listIDS.length === 0) {
              component.set('v.msgTable', 'no');
              component.set('v.errorMsgTable', $A.get('{!$Label.c.Arc_Gen_NotEEFF}'));
              component.set('v.btnStmIsDisabled', false);
            } else if (resp.ratiosStatus === 'Success') {
              msg = 'si';
              component.set('v.ffssValid', resp.ratingValidFFSS);
              component.set('v.fsServiceId', resp.fsServiceId);
              helper.checkValidFFSS(component, resp);
            } else {
              msg = 'si';
              component.set('v.ffssValid', resp.ratingValidFFSS);
              component.set('v.fsServiceId', resp.fsServiceId);
              helper.checkValidFFSS(component, resp);
              errorMessage = 'ERROR';
              errorMsg = $A.get('{!$Label.c.Cls_arce_GRP_servError}');
              helper.toastMessage(component, event, 'ERROR', 'Error: ' + errorMsg);
            }
            resolve();
          } else {
            msg = 'no';
            errorMessage = 'ERROR';
            errorMsg = $A.get('{!$Label.c.Cls_arce_GRP_servError}');
            helper.toastMessage(component, event, 'ERROR', 'Error: ' + errorMsg);
            reject();
          }
          component.set('v.msgTable', msg);
          component.set('v.errorMsgTable', errorMsg);
          component.set('v.errorMessage', errorMessage);
          component.set('v.btnStmIsDisabled', false);
          resolve();
        });
        $A.enqueueAction(action);
      } else {
        reject();
      }
    }));
  },
  setMsgErrorEngine: function(component, resp) {
    let toIndex = resp.ratiosErrorMsg;
    var action = component.get('c.getSplittedMdtValue');
    action.setParams({arceConfigName: 'RatioEngine_Error_Pos'});
    action.setCallback(this, function(response) {
      let errorMessage = $A.get('{!$Label.c.Lc_arce_TablesNoUpdated}');
      if (response.getState() === 'SUCCESS' && toIndex.includes('400')) {
        let result = response.getReturnValue();
        if (result) {
          let firstPosition = result.length === 2 ? result[0] : toIndex.indexOf('errorMessage&gt;') + 16;
          let finalPosition = result.length === 2 ? result[1] : toIndex.indexOf('/errorMessage&gt;');
          errorMessage = toIndex.substring(firstPosition, finalPosition);
        }
      } else if (toIndex.includes('400')) {
        let firstPosition = toIndex.indexOf('errorMessage&gt;') + 16;
        let finalPosition = toIndex.indexOf('/errorMessage&gt;');
        errorMessage = toIndex.substring(firstPosition, finalPosition);
      } else if (toIndex.includes('50')) {
        errorMessage = $A.get('{!$Label.c.Arc_Gen_Ratios500}');
      } else if (toIndex.includes('Error FFSS deleted')) {
        errorMessage = $A.get('{!$Label.c.Arc_Gen_FFSSDeletedInDatabase}');
      }
      component.set('v.errorMessage', errorMessage);
    });
    $A.enqueueAction(action);
  },
  setMsgTableErrorEngine: function(resp) {
    let toIndex = resp.ratiosErrorMsg;
    let errorMsg = resp.ratiosStatus;

    if (toIndex.includes('400') || toIndex.includes('50')) {
      errorMsg = $A.get('{!$Label.c.Arc_Gen_engineServiceError}');
    }
    return errorMsg;
  },
  checkValidFFSS: function(component, resp) {
    if (resp.ratingValidFFSS === 'yes') {
      var ffssValidId = resp.ratingValidatedFS;
      component.set('v.ffssValidId', ffssValidId);
    }
  },
  consultFSdetails: function(component, event, helper) {
    var action = component.get('c.consultFSdetails');
    action.setParams({
      recordId: component.get('v.accHasAnalysisId'),
      fsServiceId: component.get('v.fsServiceId'),
      isProposal: component.get('v.isProposal')
    });
    action.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        let resp = response.getReturnValue();
        helper.controlErrors(component, helper, event, resp);
        helper.refreshComponent(component);
      } else {
        var errors = response.getError();
        var errorMsg = (errors[0] && errors[0].message) ? errors[0].message : $A.get('{!$Label.c.Cls_arce_GRP_servError}');
        helper.toastMessage(component, event, 'ERROR', 'Error: ' + errorMsg);
      }
    });
    $A.enqueueAction(action);
  },
  controlErrors: function(component, helper, event, resp) {
    if (resp.gblSuccessOperation === false) {
      helper.toastMessage(component, event, 'ERROR', 'Error: ' + resp.gblResulError);
    } else if (resp.gblSuccessOperation === true && resp.gblRespServiceCode !== 200 && component.get('v.msgTable') === 'si' && component.get('v.ffssValid') === 'yes') {
      helper.toastMessage(component, event, 'ERROR', 'Error: ' + resp.gblRespServiceCode);
    }
  },
  toastMessage: function(component, event, type, message) {
    var toastMess = $A.get('e.force:showToast');
    toastMess.setParams({
      'title': '',
      'type': type,
      'mode': 'sticky',
      'duration': '8000',
      'message': message
    });
    toastMess.fire();
  },
  refreshComponent: function(component) {
    if (component.get('v.isRAIP') === false) {
      var tabRefresh = $A.get('e.dyfr:SaveObject_evt');
      tabRefresh.setParams({
        recordId: component.get('v.proposalFolderArceId')
      });
      tabRefresh.fire();
    }
  },
  evtSelectionFFSS: function(component, selectedRows) {
    var validLabel = component.get('v.validLabel');
    var cmpEvent = component.getEvent('ffssSelectionEvent');
    cmpEvent.setParams({
      'isValidFfss': selectedRows[0].arce__ffss_valid_type__c === validLabel
    });
    cmpEvent.fire();
  },
  evtSelectionFFSSValid: function(component) {
    var ffsslist = component.get('v.acctList');
    var hasValidType = false;
    hasValidType = ffsslist.some(function(element) {
      var normalize = element.arce__ffss_valid_type__c.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');
      return  (normalize === 'valid' || normalize === 'valido');
    });
    var cmpEvent = component.getEvent('ffssSelectionCheckEvent');
    cmpEvent.setParams({
      'oneValidFFSS': hasValidType
    });
    cmpEvent.fire();
  },
  evtUpdateBalances: function(component) {
    var cmpEventTrue = component.getEvent('updateBlances');
    cmpEventTrue.setParams({
      'updatedRatios': 'true'
    });
    cmpEventTrue.fire();
  },
  isPreselected: function(component, selectedRows) {
    var preselectedFFSS = component.get('v.anchorEEFF');
    var isPreselected = true;
    selectedRows.forEach(function(elem) {
      if (preselectedFFSS !== undefined && (preselectedFFSS.size === 0 || elem.arce__financial_statement_id__c === preselectedFFSS)) {
        isPreselected = false;
      }
    });
    return isPreselected;
  },
  setPreselected: function(component, event, helper, responseWrapper) {
    var preSelectedRows = [];
    var preselectedFFSS = component.get('v.anchorEEFF') !== undefined ||
    component.get('v.anchorEEFF') !== '' ? new Set(responseWrapper.preselected) : component.get('v.anchorEEFF');

    responseWrapper.ffssListLabel.forEach(function(elem) {
      if (preselectedFFSS.has(elem.arce__financial_statement_id__c)) {
        component.set('v.anchorEEFF', elem.arce__financial_statement_id__c);
        preSelectedRows.push(elem.arce__financial_statement_id__c);
        component.set('v.btnStmIsDisabled', false);
        elem.arce__Order__c = '1';
      }
    });
  },
  setPreselectedRTC: function(component, event, helper, responseWrapper) {
    if (responseWrapper.ffssList.length > 0) {
      var preSelectedRows = [];
      responseWrapper.ffssList.forEach(function(elem) {
        preSelectedRows.push(elem.arce__financial_statement_id__c);

      });
      component.set('v.preSelectedRows', preSelectedRows);
      component.set('v.selectedRows2', preSelectedRows);
      component.set('v.selectedRows', preSelectedRows);
      helper.evtSelectionFFSS(component, preSelectedRows);
    } else {
      component.set('v.ffssErrorMsg', $A.get('{!$Label.c.Arc_Gen_RTC_FFSS_NoValid}'));
    }
  },
  removeZeroFFSSId: function(ffssListLabel) {
    ffssListLabel.map(el =>{
      el.shortId = el.arce__financial_statement_id__c.replace(/^0+/, '');
    });
    return ffssListLabel;
  },
  sortBy: function(field, reverse, primer) {
    var key = primer
      ? function(x) {
        return primer(x[field]);
      }
      : function(x) {
        return x[field];
      };

    return function(a, b) {
      a = key(a);
      b = key(b);
      return reverse * ((a > b) - (b > a));
    };
  },

  handleSort: function(cmp, event) {
    var sortedBy = event.getParam('fieldName');
    var sortDirection = event.getParam('sortDirection');
    var data = cmp.get('v.acctList');
    var cloneData = data.slice(0);
    cloneData.sort((this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1)));

    cmp.set('v.acctList', cloneData);
    cmp.set('v.sortDirection', sortDirection);
    cmp.set('v.sortedBy', sortedBy);
  },
  saveEdition: function(component, helper, draftValues) {
    var selectedRows = JSON.stringify(component.get('v.selectedRows2'));
    var eeffList = component.get('v.acctList');
    var action = component.get('c.saveEEFF');
    action.setParams({
      fflist: eeffList,
      draft: draftValues,
      selectedRows: selectedRows
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        component.set('v.errors', []);
        component.set('v.draftValues', []);
        var ffssListLabel = helper.removeZeroFFSSId(response.getReturnValue());
        component.set('v.acctList', ffssListLabel);
      }
    });
    $A.enqueueAction(action);
  },
  autoOrder: function(component, setRows) {
    var acctList = component.get('v.acctList');
    for (var i = 0; i < acctList.length; i++) {
      if (setRows.has(acctList[i].arce__financial_statement_id__c)) {
        if (!acctList[i].arce__Order__c) {
          acctList[i].arce__Order__c = setRows.size.toString();
        }
      } else {
        acctList[i].arce__Order__c = '';
      }
    }
    component.set('v.acctList', acctList);
  }
});