({
  initializeComponent: function(component, event, helper) {
    let promiseInitCmp = helper.initModeCmp(component, event, helper);
    promiseInitCmp.then(function() {
      if (component.get('v.currentStep') === '3') {
        let promiseInitDeleg = helper.initDelegation(component, event, helper);
        promiseInitDeleg.then(function() {
          helper.evaluateDelegation(component, event, helper);
        });
      } else {
        helper.validateRatingP(component, event, helper);
      }
    });
  },
  initModeCmp: function(component, event, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var action = component.get('c.initModeCmp');
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var resp = response.getReturnValue();
          component.set('v.modeLight', resp);
          if (resp) {
            component.set('v.currentStep', '3');
            component.set('v.title', $A.get('$Label.c.Arc_Gen_BtnPropose'));
          } else {
            component.set('v.title', $A.get('$Label.c.ARC_GEN_PROPOSE_PREVIOUS_SUBSIDIARY'));
          }
          resolve();
        } else {
          helper.executeError(component, event, helper, response.getError()[0].message);
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  initDelegation: function(component2, event, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var inputAttributes = component2.get('v.inputAttributes');
      var action = component2.get('c.initDelegation');
      action.setParams({
        accHasAnalysisId: inputAttributes.recordId
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var resp = JSON.parse(response.getReturnValue());
          if (resp.codStatus === 200) {
            component2.set('v.delegationWrapper', response.getReturnValue());
            component2.set('v.arceId', resp.analysisId);
            component2.set('v.listAmbits', resp.lstAmbits);
            component2.set('v.spinnerStatus', false);
            if (resp.msgInfo !== '') {
              helper.showToast('success', resp.msgInfo);
            }
            helper.updateSnctnType(component2, event, helper);
            helper.validateRatingP(component2, event, helper);
            resolve();
          } else if (resp.codStatus === 500) {
            component2.set('v.disableButtons', true);
            helper.executeError(component2, event, helper, response.getError()[0].message);
            reject();
          }
        } else {
          component2.set('v.disableButtons', true);
          helper.executeError(component2, event, helper, response.getError()[0].message);
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  evaluateDelegation: function(component, event, helper) {
    component.set('v.spinnerStatus', true);
    var inputAttributes = component.get('v.inputAttributes');
    var action = component.get('c.evaluateDelegation');
    action.setParams({
      wrapper: component.get('v.delegationWrapper'),
      accHasAnalysisId: inputAttributes.recordId
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var res = JSON.parse(response.getReturnValue());
        if (res.codStatus === 201) {
          if (res.msgInfo !== '') {
            helper.showToast('success', res.msgInfo);
          }
          helper.refreshTab(component, event, helper);
          helper.cancelAction(component);
        } else if (res.codStatus === 200) {
          component.set('v.currentStep', '3');
          component.set('v.spinnerStatus', false);
        } else if (res.codStatus === 500) {
          component.set('v.disableButtons', true);
          component.set('v.spinnerStatus', true);
          helper.showToast('error', res.msgInfo);
        }
      } else {
        component.set('v.disableButtons', true);
        helper.executeError(component, event, helper, response.getError()[0].message);
      }
    });
    $A.enqueueAction(action);
  },
  validateRatingP: function(component, event, helper) {
    var inputAttributes = component.get('v.inputAttributes');
    var actionR = component.get('c.validateRatingInSanction');
    actionR.setParams({
      'accHasAnalysisId': inputAttributes.recordId
    });
    actionR.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = response.getReturnValue();
        if (resp) {
          component.set('v.spinnerStatus', false);
          component.set('v.getCustomersBoolean', true);
          helper.getAllCustomers(component, event, helper);
        } else {
          helper.showToast('error', $A.get('{!$Label.c.Arc_Gen_VRating_Error}'));
          component.set('v.disableButtons', true);
        }
      } else {
        helper.executeError(component, event, helper, response.getError()[0].message);
        component.set('v.disableButtons', true);
      }
    });
    $A.enqueueAction(actionR);
  },
  updateSnctnType: function(component, event, helper) {
    var action = component.get('c.updateSnctnType');
    action.setParams({
      wrapper: component.get('v.delegationWrapper')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state !== 'SUCCESS') {
        component.set('v.disableButtons', true);
        helper.executeError(component, event, helper, response.getError()[0].message);
      }
    });
    $A.enqueueAction(action);
  },
  getAllCustomers: function(component, event, helper) {
    var inputAttributes = component.get('v.inputAttributes');
    var action = component.get('c.getCustomerDatactrl');
    var getCustomersBoolean = component.get('v.getCustomersBoolean');
    action.setParams({
      'appear': getCustomersBoolean,
      'accHasAnalysisId': inputAttributes.recordId
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var storeResponse = response.getReturnValue();
        var mapa = storeResponse.mapAccHasAnalysis;
        component.set('v.listComboBox', storeResponse.mapComboBox);
        component.set('v.mapCustomers', mapa);
        component.set('v.spinnerStatus', false);
      } else {
        component.set('v.disableButtons', true);
        helper.executeError(component, event, helper, response.getError()[0].message);
      }
    });
    $A.enqueueAction(action);
  },
  updateMainSubsidiary: function(element, component) {
    var action = component.get('c.updateMainSubsidiary');
    action.setParams({
      'element': element
    });
    $A.enqueueAction(action);
  },
  getStageValues: function(component, event, helper) {
    var action = component.get('c.getStagePicklist');
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var storeResponse = response.getReturnValue();
        component.set('v.listStages', storeResponse);
        component.set('v.spinnerStatus', false);
      } else {
        component.set('v.disableButtons', true);
        helper.executeError(component, event, helper, response.getError()[0].message);
      }
    });
    $A.enqueueAction(action);
  },
  updateStageSetValues: function(component, event, helper) {
    var inputAttributes = component.get('v.inputAttributes');
    var action = component.get('c.updateStagesetDataCtrl');
    action.setParams({
      'accHasAnalysisId': inputAttributes.recordId,
      'stage': component.get('v.stagevalue')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        component.set('v.currentStep', '3');
        component.set('v.title', $A.get('$Label.c.Arc_Gen_BtnPropose'));
      } else {
        component.set('v.disableButtons', true);
        helper.executeError(component, event, helper, response.getError()[0].message);
      }
    });
    $A.enqueueAction(action);
  },
  setAmbit: function(component, event, helper, ambit, recordId) {
    var inputAttributes = component.get('v.inputAttributes');
    var action = component.get('c.setAmbitCtrl');
    action.setParams({
      'ambit': component.get('v.ambit'),
      'accHasAnalysisId': inputAttributes.recordId,
      'wrapper': component.get('v.delegationWrapper')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var res = JSON.parse(response.getReturnValue());
        if (res.codStatus === 201 || res.codStatus === 200) {
          if (res.msgInfo !== '') {
            helper.showToast('success', res.msgInfo);
          }
          helper.cancelAction(component);
          helper.refreshTab(component, event, helper);
          window.location.reload();
        } else {
          helper.executeError(component, event, helper, response.getError()[0].message);
        }
      } else {
        component.set('v.disableButtons', true);
        helper.executeError(component, event, helper, response.getError()[0].message);
      }
    });
    $A.enqueueAction(action);
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
  refreshTab: function(component, event, helper) {
    let refreshEvt = $A.get('e.c:Arc_Gen_QVCDRefresh_evt');
    refreshEvt.fire();
  },
  cancelAction: function(component) {
    component.destroy();
  },
  executeError: function(component, event, helper, msgError) {
    helper.showToast('error', msgError);
    helper.cancelAction(component);
  },
  persistArceAction: function(cmp1, evt, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var inputAttributes = cmp1.get('v.inputAttributes');
      var action = cmp1.get('c.persistArceAction');
      action.setParams({
        wrapper: cmp1.get('v.delegationWrapper'),
        accHasAnalysisId: inputAttributes.recordId
      });
      action.setCallback(this, function(response1) {
        var state = response1.getState();
        if (state === 'SUCCESS') {
          var resp = JSON.parse(response1.getReturnValue());
          if (resp.codStatus === 200) {
            resolve();
          } else {
            reject($A.get('$Label.c.Arc_Gen_ServicePersistenceError'));
          }
        } else {
          reject(response1.getError()[0].message);
        }
      });
      $A.enqueueAction(action);
    }));
  }
});