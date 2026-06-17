({
  fetchFinancialStatements: function(component, event, helper) {
    var action = component.get('c.fetchFinancialStatements');
    action.setParams({
      varRecord: component.get('v.accHasAnalysisId'),
      isFinancialRAIP: component.get('v.isFinancialRAIP'),
      ratingToolSelect: component.get('v.ratingToolSelect'),
      requestedPage: component.get('v.currentPage')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var responseWrapper = response.getReturnValue();
        helper.setPreselected(component, event, helper, responseWrapper);

        helper.setupPagination(component, responseWrapper);
        helper.setValues(component, helper, responseWrapper);
        component.set('v.spinnerLoading', false);
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
    var ffssListLabel = helper.removeZeroFFSSId(responseWrapper.ffssListLabel);
    var acctList = component.get('v.acctList');
    var ffssList = component.get('v.ffssList');
    ffssListLabel.forEach(function(element) {
      acctList.push(element);
    });
    responseWrapper.ffssList.forEach(function(element) {
      ffssList.push(element);
    });
    component.set('v.acctList', acctList);
    component.set('v.ffssList', ffssList);
    component.set('v.validLabel', responseWrapper.validLabel);
  },
  setColumns: function(component) {
    var action = component.get('c.dynamicColumnsRTC');
    action.setParams({
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
  handleClickRating: function(component, event, helper) {
    var ratingType = event.getSource().get('v.value');
    if (ratingType === 'Rating') {
      component.set('v.variantRating', 'brand');
      component.set('v.variantPreRating', 'neutral');
    } else {
      component.set('v.variantRating', 'neutral');
      component.set('v.variantPreRating', 'brand');
    }
    component.set('v.ratingType', ratingType);
    component.set('v.nextDisabled', false);
    helper.enableNextButton(component, true);
  },
  isPreselected: function(component, selectedRows) {
    var preselectedFFSS = new Set(component.get('v.preSelectedRows'));
    var isPreselected = true;
    selectedRows.forEach(function(elem) {
      if (preselectedFFSS.size === 0 || preselectedFFSS.has(elem.arce__financial_statement_id__c)) {
        isPreselected = false;
      }
    });
    return isPreselected;
  },
  setPreselected: function(component, event, helper, responseWrapper) {
    if (responseWrapper.ffssList.length > 0) {
      var preSelectedRows = [];
      responseWrapper.ffssList.forEach(function(elem) {
        if (elem.arce__ffss_apply_for_rating_type__c === '1') {
          preSelectedRows.push(elem.arce__financial_statement_id__c);
          helper.enableNextButton(component, true);

          component.set('v.nextDisabled', false);
          if (!component.get('v.showRating')) {
            component.set('v.ratingType', 'PreRating');
            component.set('v.variantPreRating', 'brand');
          } else {
            component.set('v.ratingType', 'Rating');
            component.set('v.variantRating', 'brand');
          }

        }

      });
      component.set('v.preSelectedRows', preSelectedRows);
      component.set('v.selectedRows2', preSelectedRows);
      component.set('v.selectedRows', preSelectedRows);
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
  },
  enableNextButton: function(component, enabled) {
    const wzrdEvent = component.getEvent('wizardEvent');
    wzrdEvent.setParams({
      eventType: 'nextEnable',
      parameters: { enabled }
    });
    wzrdEvent.fire();
  },
  showError: function(component31, message) {
    const wzrdEvent = component31.getEvent('wizardEvent');
    wzrdEvent.setParams({
      eventType: 'showError',
      parameters: { error: message }
    });
    wzrdEvent.fire();
  },
  isRatingAvaiable: function(component) {
    var action = component.get('c.isRating');
    action.setParams({
      modelSelec: component.get('v.modlSlctd'),
      ratingSys: component.get('v.ratingSys'),
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var responseWrapper = response.getReturnValue();
        component.set('v.showRating', responseWrapper);
      }
      component.set('v.spinnerLoading', false);
    });
    $A.enqueueAction(action);
  },
  getVariablesButton: function(component, event, helper) {
    var analysisId = '';
    var pathArray = window.location.href.split('/');
    for (let aux = 0; aux < pathArray.length; aux++) {
      if (pathArray[aux] === 'arce__Analysis__c') {
        analysisId = pathArray[aux + 1];
      }
    }

    component.set('v.spinnerLoading', true);
    var action = component.get('c.getVariablesButton');
    action.setParams({
      analysisId: analysisId
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var responseWrapper = response.getReturnValue();

        if (responseWrapper !== null) {
          component.set('v.modlSlctd', responseWrapper.modlSlctd);
          component.set('v.accHasAnalysisId', responseWrapper.accHasAnalysisId);
          component.set('v.ratingType', responseWrapper.ratingType);

          helper.fetchFinancialStatements(component, event, helper);
          helper.isRatingAvaiable(component);
          helper.checkNplStatus(component, event, helper);
        }
      }
    });
    $A.enqueueAction(action);
  },
  refreshComponent: function(component) {
    if (component.get('v.fromButton') === true) {
      var tabRefresh = $A.get('e.dyfr:SaveObject_evt');
      tabRefresh.setParams({
        recordId: component.get('v.accHasAnalysisId')
      });
      tabRefresh.fire();
    }
  },
  consultEngine: function(component, event, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var listIDS = JSON.stringify(component.get('v.selectedRows2'));
      var errorMsg = '';
      component.set('v.spinnerLoading', true);

      var action = component.get('c.callEngineFinancialState');
      action.setParams({
        recordId: component.get('v.accHasAnalysisId'),
        fflist: component.get('v.acctList'),
        financialIdList: component.get('v.selectedRows2'),
        isRAIP: true,
        isFinancialRAIP: component.get('v.isFinancialRAIP'),
        ratingToolSelect: component.get('v.ratingType'),
        selectedRows: listIDS
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          component.set('v.draftValues', []);
          component.set('v.show', false);
          helper.refreshComponent(component);
          resolve();
        } else {
          errorMsg = $A.get('{!$Label.c.Cls_arce_GRP_servError}');
          component.set('v.ffssErrorMsg', errorMsg);
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  updateRatingState: function(component, isNotAnyApply) {
    if (!component.get('v.showRating')) {
      component.set('v.disabledPreRating', isNotAnyApply);
    } else {
      component.set('v.disabledRating', isNotAnyApply);
    }
  },
  checkNplStatus: function(component, event, helper) {
    if (component.get('v.showRating') === true) {
      var action = component.get('c.checkNplStatus');
      action.setParams({
        ahaId: component.get('v.accHasAnalysisId'),
        model: component.get('v.modlSlctd')
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var value = response.getReturnValue();
          component.set('v.showRating', value);
          if (value === false) {
            helper.toastMessage(component, event, 'warning', 'Clients NPL status only allows Pre-Rating');
          }
        } else {
          var errors = response.getError();
          helper.toastMessage(component, event, 'error', errors[0].message);
        }
        component.set('v.spinnerLoading', false);
      });
      $A.enqueueAction(action);
    }
  }
});