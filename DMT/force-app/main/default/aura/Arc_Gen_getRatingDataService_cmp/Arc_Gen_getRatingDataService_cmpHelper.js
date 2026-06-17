({
  getInfoAnalysis: function(component, event, helper) {
    return new Promise($A.getCallback((resolve, reject) => {
      var action = component.get('c.getAnalysis');
      action.setParams({
        accHasId: component.get('v.hasRecordId')
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var obj = response.getReturnValue();
          component.set('v.analysisObj', obj);
          helper.getCustomerId(component, helper)
            .then(function() {
              resolve();
            }).catch(function() {
              reject();
            });
        } else {
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  validationsBeforeCall: function(component12, event, helper) {
    return new Promise($A.getCallback((resolve, reject) => {
      return Promise.all([
        helper.validationQualitativeQuestion(component12, event, helper)
      ])
        .then(values => {
          if (this.isEmptyVal(values)) {
            component12.set('v.lstMsg', values);
            helper.cancelAction(component12);
          } else {
            resolve();
          }
        })
        .catch(error => {
          reject(error);
        });
    }));
  },
  validationQualitativeQuestion: function(component, event, helper) {
    return new Promise($A.getCallback((resolve, reject) => {
      var action = component.get('c.validationQualitativeQuestion');
      action.setParams({
        accHasId: component.get('v.hasRecordId'),
        analysis: component.get('v.analysisObj')
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var mapEmptyFc = response.getReturnValue();
          if (Object.keys(mapEmptyFc).length > 0) {
            var arrayMapKeys = [];
            for (var key in mapEmptyFc) {
              if (Object.prototype.hasOwnProperty.call(mapEmptyFc, key)) {
                arrayMapKeys.push({key: key, value: mapEmptyFc[key]});
              }
            }
            component.set('v.mapEmptyFc', arrayMapKeys);
            component.set('v.showEmptyFc', true);
            component.set('v.errorTitle', $A.get('{!$Label.c.Arc_Gen_RatingError_CalculateError}'));
            component.set('v.message', $A.get('{!$Label.c.Arc_Gen_QualitativeQuestionError}'));
            resolve($A.get('{!$Label.c.Arc_Gen_QualitativeQuestionError}'));
          } else {
            resolve();
          }
        } else {
          helper.showToast($A.get('{!$Label.c.Lc_arce_newAnalysisError}'), response.getError());
          $A.get('e.force:closeQuickAction').fire();
          reject(response.getError());
        }
      });
      $A.enqueueAction(action);
    }));
  },
  getCustomerId: function(component, helper) {
    var action = component.get('c.getCustomerData');
    action.setParams({
      analysisId: component.get('v.hasRecordId')
    });

    return new Promise($A.getCallback(function(resolve, reject) {
      action.setCallback(this, function(response) {
        var resp = response.getReturnValue();
        var state = response.getState();
        if (state === 'SUCCESS') {
          component.set('v.customerName', resp.customerName);
          component.set('v.customerId', resp.customerId);
          resolve();
        } else {
          helper.showToast($A.get('{!$Label.c.Lc_arce_newAnalysisError}'), resp.errorMessage);
          $A.get('e.force:closeQuickAction').fire();
          reject();
        }
      });

      $A.enqueueAction(action);
    }));
  },
  callRatingEngine: function(component, helper, className) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var action = component.get(className);
      action.setParams({
        analysisId: component.get('v.hasRecordId'),
        customerId: component.get('v.customerId'),
        serviceMock: null
      });
      action.setCallback(this, function(response) {
        var resp = response.getReturnValue();
        var state = response.getState();
        if (state === 'SUCCESS') {
          if (resp.serviceCode === '200' && resp.saveStatus === 'true') {
            resolve('true');
          } else if (resp.serviceCode !== '200') {
            var errorWrapper = JSON.parse(resp.serviceMessage);
            component.set('v.errorCode', $A.get('{!$Label.c.Arc_Gen_RatingError_ErrorCode}') + ' ' + errorWrapper.errorCode);
            component.set('v.errorTitle', errorWrapper.errorTitle);
            component.set('v.message', errorWrapper.errorMessage);
            reject();
          }
          if (resp.saveStatus === 'false') {
            component.set('v.message', $A.get('{!$Label.c.Lc_arce_newAnalysisError}') + resp.saveMessage);
            reject();
          }
        } else {
          $A.get('e.force:showToast');
          component.set('v.message', $A.get('{!$Label.c.Lc_arce_newAnalysisError}'));
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  refreshRating: function(component) {
    var tabRefresh = $A.get('e.dyfr:SaveObject_evt');
    tabRefresh.setParams({
      'recordId': component.get('v.recordId')
    });
    tabRefresh.fire();
  },
  showToast: function(title, mensaje) {
    var resultsToast = $A.get('e.force:showToast');
    resultsToast.setParams({
      'title': title,
      'type': 'error',
      'message': mensaje,
      'duration': '8000'
    });
    resultsToast.fire();
  },
  cancelAction: function(component) {
    component.set('v.success', 'no');
    component.set('v.spinner', 'false');
  },
  isEmptyVal: function(values) {
    var boolVal = false;
    for (var key in values) {
      if (values[key] !== undefined) {
        boolVal = true;
      }
    }
    return boolVal;
  },
  invokeServices: function(component, helper) {
    helper.callPersQualitativeIRP(component)
      .then(function() {
        helper.persistFFSS(component, helper)
          .then(function(resolvePersist) {
            helper.callRatingEngine(component, helper, 'c.setupRating')
              .then(function(resolve2) {
                if (resolve2 === 'true') {
                  component.set('v.message', $A.get('{!$Label.c.Lc_arce_successAndCloseWindow}'));
                  component.set('v.success', 'yes');
                  helper.refreshRating(component);
                  component.set('v.spinner', 'false');
                }
              })
              .catch(function(error) {
                helper.cancelAction(component);
              });
          })
          .catch(function(errorPersist) {
            helper.cancelAction(component);
          });
      });
  },
  callPersQualitativeIRP: function(component) {
    return new Promise($A.getCallback((resolve, reject) => {
      var action = component.get('c.callPersistModifiers');
      action.setParams({
        aHasAnalysId: component.get('v.recordId'),
        methodType: 'persistenceOverlays',
        analysisObj: component.get('v.analysisObj')
      });
      component.set('v.isLoading', true);
      action.setCallback(this, function(response) {
        var state = response.getState();
        var resp = response.getReturnValue();
        if (state === 'SUCCESS' && (resp.serviceCode === '200' || resp.serviceCode === '201' || resp.serviceCode === '204')) {
          resolve();
        } else {
          var info = response.getReturnValue();
          component.set('v.formIncompleteInfo', info);
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  persistFFSS: function(component, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var action = component.get('c.persistFFSS');
      action.setParams({
        ahaId: component.get('v.hasRecordId')
      });
      action.setCallback(this, function(response) {
        var resp = response.getReturnValue();
        var state = response.getState();
        if (state === 'SUCCESS') {
          if (resp.serviceCode === '200') {
            resolve('true');
          } else {
            var errorWrapper = JSON.parse(resp.serviceMessage);
            component.set('v.errorCode', $A.get('{!$Label.c.Arc_Gen_ServicePersistenceError}') + ' ' + errorWrapper.errorCode);
            component.set('v.errorTitle', errorWrapper.errorTitle);
            component.set('v.message', errorWrapper.errorMessage);
            reject();
          }
        } else {
          $A.get('e.force:showToast');
          component.set('v.message', $A.get('{!$Label.c.Arc_Gen_ServicePersistenceError}'));
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
});