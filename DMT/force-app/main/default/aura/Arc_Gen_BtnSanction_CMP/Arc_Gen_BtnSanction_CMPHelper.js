({
  getArceData: function(cmp, evt, helper) {
    var action = cmp.get('c.getAnalysisData');
    action.setParams({
      'acchasid': cmp.get('v.inputAttributes').recordId
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      var resp = response.getReturnValue();
      if (state === 'SUCCESS') {
        cmp.set('v.analysisId', resp[0].Id);
        if (resp[0].arce__anlys_wkfl_sub_process_type__c === '3') {
          cmp.set('v.disabledDate', true);
          cmp.set('v.sancdateCometee', resp[0].arce__analysis_risk_expiry_date__c);
        }
      }
    });
    $A.enqueueAction(action);
  },
  initializeComponent: function(cmp, evt, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      let promise = helper.initDelegation(cmp, evt, helper);
      promise.then(function() {
        resolve();
      });
    }));
  },
  initDelegation: function(cmp2, evt, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var inputAttributes = cmp2.get('v.inputAttributes');
      var action = cmp2.get('c.initDelegation');
      action.setParams({
        accHasAnalysisId: inputAttributes.recordId
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var resp = JSON.parse(response.getReturnValue());
          if (resp.codStatus === 200) {
            cmp2.set('v.delegationWrapper', response.getReturnValue());
            cmp2.set('v.listAmbits', resp.lstAmbits);
            cmp2.set('v.listActions', resp.lstActions);
            resolve();
          } else if (resp.codStatus === 500) {
            helper.executeError(cmp2, evt, helper, resp.msgInfo);
            reject();
          }
        } else {
          helper.executeError(cmp2, evt, helper, response.getError()[0].message);
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  validatesave: function(cmp, helper) {
    var descValue = cmp.find('descText').get('v.value');
    cmp.set('v.descValue', descValue);
    var opt = typeof (cmp.get('v.selectedAction')) === 'undefined' ? '' : cmp.get('v.selectedAction');
    var sancdateField = cmp.find('sancdate');
    var sancDate = sancdateField.get('v.value');
    var sancDateCometee = cmp.get('v.sancdateCometee');
    var idUserSelected = cmp.get('v.idUserSelected');

    if (!descValue) {
      descValue = '';
    }

    helper.checkSanctionDate(cmp, sancDateCometee);

    if (sancDate !== '' && sancDate !== null && sancDateCometee !== '' && sancDateCometee !== null && idUserSelected !== '' && descValue !== '' &&
        opt !== '' && sancdateField.get('v.validity').valid) {
      helper.checkAmbitValidation(cmp);
    } else {
      cmp.set('v.isVisibleBtn', true);
    }
  },
  checkAmbitValidation: function(cmp) {
    if (cmp.get('v.lstAmbitVisibility')) {
      if (cmp.get('v.selectedAmbit') !== undefined) {
        cmp.set('v.isVisibleBtn', false);
      }
    } else {
      cmp.set('v.isVisibleBtn', false);
    }
  },
  checkSanctionDate: function(cmp, sancDateCometee) {
    var today3Months = new Date().setMonth(new Date().getMonth() + 3);
    var check = sancDateCometee !== null && cmp.get('v.disabledDate') === false && new Date(sancDateCometee) < today3Months;
    cmp.set('v.showSancdateCometeeWarning', check);
  },
  saveAction: function(cmp, evt, helper) {
    var inputAttributes = cmp.get('v.inputAttributes');
    var actionCall = cmp.get('c.saveScopeOfSanction');
    var params = {};
    params = {
      'recordId': inputAttributes.recordId,
      'idUserSelected': cmp.get('v.idUserSelected'),
      'userSelected': cmp.get('v.userSelected'),
      'ambit': cmp.get('v.selectedAmbit'),
      'sanction': cmp.get('v.selectedAction'),
      'descText': cmp.get('v.descValue'),
      'sancDate': cmp.get('v.sancdate'),
      'sancdateCometee': cmp.get('v.sancdateCometee'),
    };
    actionCall.setParams({
      'wrapper': cmp.get('v.delegationWrapper'),
      data: params
    });
    return new Promise($A.getCallback(function(resolve, reject) {
      actionCall.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var resp = JSON.parse(response.getReturnValue());
          if (resp.codStatus === 200) {
            if (resp.msgInfo !== '') {
              helper.showToast('success', resp.msgInfo);
            }
            resolve();
          } else if (resp.codStatus === 500) {
            helper.executeError(cmp, evt, helper, resp.msgInfo);
            reject();
          }
        } else {
          helper.executeError(cmp, evt, helper, response.getError()[0].message);
          reject();
        }
      });
      $A.enqueueAction(actionCall);
    }));
  },
  showToast: function(type, message) {
    var toastEventUE = $A.get('e.force:showToast');
    toastEventUE.setParams({
      'title': '',
      'type': type,
      'mode': 'sticky',
      'duration': '8000',
      'message': message
    });
    toastEventUE.fire();
  },
  cancelAction: function(cmp) {
    cmp.set('v.isVisibleBtn', true);
    cmp.set('v.spinnerStatus', true);
    cmp.destroy();
  },
  executeError: function(cmp, evt, helper, msgError) {
    helper.showToast('error', msgError);
    helper.cancelAction(cmp);
  },
  refreshTab: function(cmp, evt, helper) {
    let refreshEvt = $A.get('e.c:Arc_Gen_QVCDRefresh_evt');
    refreshEvt.fire();
    window.location.reload();
  },
  callPersistences: function(cmp, evt, helper) {
    var action = cmp.get('c.callPersistences');
    var params = {
      'analysisId': cmp.get('v.analysisId'),
      'sanctionSel': cmp.get('v.selectedAction'),
      'idUserSelected': cmp.get('v.idUserSelected'),
      'sancdateCometee': cmp.get('v.sancdateCometee')
    };
    action.setParams({
      data: params
    });
    return new Promise($A.getCallback(function(resolve, reject) {
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var resp = response.getReturnValue();
          if (resp === true) {
            helper.refreshTab(cmp, evt, helper);
            helper.cancelAction(cmp);
            resolve();
          } else {
            helper.executeError(cmp, evt, helper, $A.get('$Label.c.Arc_Gen_ServicePersistenceError'));
            reject();
          }
        } else {
          helper.executeError(cmp, evt, helper, $A.get('$Label.c.Arc_Gen_ServicePersistenceError'));
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  }
});