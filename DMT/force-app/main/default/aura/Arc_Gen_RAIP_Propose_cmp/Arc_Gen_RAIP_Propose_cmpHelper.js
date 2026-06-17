({
  initDelegation: function(component, event, helper) {
    return new Promise($A.getCallback((resolve, reject) => {
      var inputAttributes = component.get('v.inputAttributes');
      var action = component.get('c.initDelegation');
      action.setParams({ 
        accHasAnalysisId: inputAttributes.recordId
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var resp = JSON.parse(response.getReturnValue());
          if (resp.codStatus === 200) {
            component.set('v.isRatingCalculated', true);
            component.set('v.delegationWrapper', resp);
            resolve();
          } else if (resp.codStatus === 500) {
            helper.executeError(component, helper, 'error', resp.msgInfo);
            reject();
          }
        } else {
          component.set('v.isRatingCalculated', false);
          helper.executeError(component, helper, 'error', response.getError()[0].message);
          reject();
        }
        component.set('v.spinnerStatus', false);
      });
      $A.enqueueAction(action);
    }));
  },
  fetchUsers: function(component, event, helper) {
    var action = component.get('c.fetchUsers');
    action.setParams({
      selectedAmbit: component.get('v.selectedOption')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = JSON.parse(response.getReturnValue());
        if (resp.codStatus === 200) {
          component.set('v.deleUserWrapper', resp);
          component.set('v.isRatingCalculated', true);
        } else if (resp.codStatus === 500) {
          helper.executeError(component, helper, 'error', resp.msgInfo);
        }
      } else {
        component.set('v.isRatingCalculated', false);
        helper.executeError(component, helper, 'error', response.getError()[0].message);
      }
      component.set('v.spinnerStatus', false);
    });
    $A.enqueueAction(action);
  },
  fetchAmbit: function(component, event, helper) {
    var action = component.get('c.fetchRegionLevel');
    var inputAttributes = component.get('v.inputAttributes');
    action.setParams({
      region: component.get('v.selectedRegion'),
      level: component.get('v.selectedLevel'),
      accHasAnalysisId: inputAttributes.recordId

    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = JSON.parse(response.getReturnValue());
        if (resp.codStatus === 200) {
          component.set('v.deleAmbitWrapper', resp);
          component.set('v.isRatingCalculated', true);
        } else if (resp.codStatus === 500) {
          helper.executeError(component, helper, 'error', resp.msgInfo);
        }
      } else {
        component.set('v.isRatingCalculated', false);
        helper.executeError(component, helper, 'error', response.getError()[0].message);
      }
      component.set('v.spinnerStatus', false);
    });
    $A.enqueueAction(action);
  },
  fetchLevel: function(component, event, helper) {
    var action = component.get('c.fetchRegionLevel');
    var inputAttributes = component.get('v.inputAttributes');
    action.setParams({
      region: component.get('v.selectedRegion'),
      level: component.get('v.selectedLevel'),
      accHasAnalysisId: inputAttributes.recordId

    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = JSON.parse(response.getReturnValue());
        if (resp.codStatus === 200) {
          component.set('v.deleLevelWrapper', resp);
          component.set('v.isRatingCalculated', true);
        } else if (resp.codStatus === 500) {
          helper.executeError(component, helper, 'error', resp.msgInfo);
        }
      } else {
        component.set('v.isRatingCalculated', false);
        helper.executeError(component, helper, 'error', response.getError()[0].message);
      }
      component.set('v.spinnerStatus', false);
    });
    $A.enqueueAction(action);
  },
  proposeRaip: function(component, event, helper) {
    var wrapper = component.get('v.delegationWrapper');
    var action = component.get('c.toProposeRaip');
    action.setParams({
      arceId: wrapper.analysisId,
      selectedAmbit: component.get('v.selectedOption'),
      selectedUser: component.get('v.selectedOptionUser')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = JSON.parse(response.getReturnValue());
        if (resp.status === 'true') {
          component.set('v.modalStep', '2');
          helper.refreshTab();
        } else {
          helper.executeError(component, helper, 'error', resp.message);
        }
      } else {
        helper.executeError(component, helper, 'error', response.getError()[0].message);
      }
      component.set('v.spinnerStatus', false);
    });
    $A.enqueueAction(action);
  },
  showToast: function(type, message) {
    var toastEventUE = $A.get('e.force:showToast');
    toastEventUE.setParams({
      'title': '',
      'type': type,
      'mode': 'dismissible',
      'duration': '5000',
      'message': message
    });
    toastEventUE.fire();
  },
  cancelAction: function(component) {
    component.set('v.show', 'false');

    // If closed at second step (Finish), refresh page.
    if (component.get('v.modalStep') === '2') {
      $A.get('e.force:refreshView').fire();
    }
    component.destroy();
  },
  executeError: function(component, helper, type, msgError) {
    component.set('v.selectedOption', '');
    if (type === 'toast') {
      helper.showToast('error', msgError);
      helper.cancelAction(component);
    } else if (type === 'error') {
      component.set('v.showErrorSection', true);
      component.set('v.errorMessage', msgError);
    }
  },
  refreshTab: function() {
    window.setTimeout($A.getCallback(function() {
      window.location.reload();
    }), 2500);
  },
  checkPermission: function(component) {
    return new Promise($A.getCallback((resolve, reject) => {
      var inputAttributes = component.get('v.inputAttributes');
      var action = component.get('c.getPermissionOverlay');
      action.setParams({
        'recordId': inputAttributes.recordId,
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var resp = response.getReturnValue();
          if (resp === 'Show') {
            component.set('v.show', true);
            resolve();
          } else {
            component.set('v.show', false);
            this.showToast('WARNING', resp);
            reject();
          }
        }
      });
      $A.enqueueAction(action);
    }));
  },
  handleValidatePSResponse: function(component, helper, resp, resolve, reject) {
    if (resp.status === 'Success') {
      component.set('v.showPsRefresh', false);
      resolve();
    } else if (resp.status === 'RefreshPS') {
      helper.executeError(component, helper, 'error', resp.message);
      component.set('v.showPsRefresh', true);
      reject();
    } else {
      helper.executeError(component, helper, 'error', resp.message);
      reject();
    }
  },
  validatePS: function(component, event, helper) {
    return new Promise($A.getCallback((resolve, reject) => {
      if (!component.get('v.isCorporates') || !component.get('v.isIRPRTC')) {
        resolve();
        return;
      }

      var inputAttributes = component.get('v.inputAttributes');
      var action = component.get('c.validateParentSubsidiary');
      action.setParams({
        'ahaId': inputAttributes.recordId,
        'isTest': false
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var resp = response.getReturnValue();
          helper.handleValidatePSResponse(component, helper, resp, resolve, reject);
        } else {
          helper.executeError(component, helper, 'error', response.getError()[0].message);
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  dataQuality: function(component, event, helper) {
    return new Promise($A.getCallback((resolve, reject) => {
      if (component.get('v.isCorporates') && component.get('v.isIRPRTC')) {
        var inputAttributes = component.get('v.inputAttributes');
        var action = component.get('c.dataQuality');
        action.setParams({
          'ahaId': inputAttributes.recordId
        });
        action.setCallback(this, function(response) {
          var state = response.getState();
          if (state === 'SUCCESS') {
            var resp = response.getReturnValue();
            if (resp.status === 'Success' || (resp.status === 'RefreshWL' && component.get('v.bypassWL') === true)) {
              helper.setShowRefresh(component, event, helper);
              resolve();
            } else if (resp.status === 'RefreshGCP') {
              helper.executeError(component, helper, 'error', resp.message);
              component.set('v.showRefreshGCP', true);
              reject();
            } else if (resp.status === 'RefreshWL' && component.get('v.bypassWL') === false) {
              helper.executeError(component, helper, 'error', resp.message);
              component.set('v.showRefreshWL', true);
              reject();
            }  else if (resp.status === 'Error') {
              helper.executeError(component, helper, 'error', resp.message);
              reject();
            }
          } else {
            helper.executeError(component, helper, 'error', response.getError()[0].message);
            reject();
          }
        });
        $A.enqueueAction(action);
      } else {
        resolve();
      }
    }));
  },
  setShowRefresh: function(component, event, helper) {
    component.set('v.showRefreshGCP', false);
    component.set('v.showRefreshWL', false);
  },
  refreshPS: function(component, event, helper) {
    var inputAttributes = component.get('v.inputAttributes');
    var action = component.get('c.refreshParentSubsidiary');
    action.setParams({
      'ahaId': inputAttributes.recordId,
      'isTest': false
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = response.getReturnValue();
        if (resp.status === 'Success') {
          helper.showToast('success', 'Parent Subsidiary data was successfuly retrieved!');
          $A.get('e.force:refreshView').fire();
          component.destroy();
        } else {
          helper.executeError(component, helper, 'error', resp.message);
          component.set('v.showPsRefresh', true);
        }
      } else {
        helper.executeError(component, helper, 'error', response.getError()[0].message);
        component.set('v.showPsRefresh', true);
      }
    });
    $A.enqueueAction(action);
  },
  refreshGCP: function(component, event, helper) {
    var inputAttributes = component.get('v.inputAttributes');
    var action = component.get('c.refreshParentRating');
    action.setParams({
      'ahaId': inputAttributes.recordId
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = response.getReturnValue();
        if (resp.status === 'Success') {
          helper.showToast('success', 'Parent Rating data was successfuly refreshed!');
          $A.get('e.force:refreshView').fire();
          component.destroy();
        } else {
          helper.executeError(component, helper, 'error', resp.message);
          component.set('v.showRefreshGCP', true);
        }
      } else {
        helper.executeError(component, helper, 'error', response.getError()[0].message);
        component.set('v.showRefreshGCP', true);
      }
    });
    $A.enqueueAction(action);
  },
  refreshWL: function(component, event, helper) {
    var inputAttributes = component.get('v.inputAttributes');
    var action = component.get('c.refreshWatchList');
    action.setParams({
      'ahaId': inputAttributes.recordId
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = response.getReturnValue();
        if (resp.status === 'Success') {
          helper.showToast('success', 'WatchList data was successfuly refreshed!');
          $A.get('e.force:refreshView').fire();
          component.destroy();
        } else {
          helper.executeError(component, helper, 'error', resp.message);
          component.set('v.showRefreshWL', true);
        }
      } else {
        helper.executeError(component, helper, 'error', response.getError()[0].message);
        component.set('v.showRefreshWL', true);
      }
    });
    $A.enqueueAction(action);
  },
  checkIsRTC: function(component, event, helper) {

    return new Promise($A.getCallback((resolve, reject) => {
      var inputAttributes = component.get('v.inputAttributes');
      var action = component.get('c.isRTC');
      action.setParams({
        'ahaId': inputAttributes.recordId,
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var isRTC = response.getReturnValue();
          component.set('v.isIRPRTC', isRTC);
          if (isRTC) {
            component.set('v.showAmbitSelection', false);
            component.set('v.recordId', inputAttributes.recordId);
          }
          resolve();
        } else {
          helper.executeError(component, helper, 'error', response.getError()[0].message);
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },

  // Get all ARCE configurations here in a single call
  // This is to avoid multiple server calls to get ARCE configurations
  // Set the ARCE configurations in the component attributes
  isCorporates: function(component, event, helper) {
    return new Promise($A.getCallback((resolve, reject) => {
      var action = component.get('c.isCorporates');
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          const resp = JSON.parse(response.getReturnValue());
          const isCorporates = resp.Is_Corporate === 'true';
          component.set('v.isCorporates', isCorporates);
          resolve();
        } else {
          helper.executeError(component, helper, 'error', response.getError()[0].message);
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },

  checkIsARP: function(component, event, helper) {

    return new Promise((resolve, reject) => {
      var inputAttributes = component.get('v.inputAttributes');
      var action = component.get('c.isARP');
      action.setParams({
        'ahaId': inputAttributes.recordId,
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var isARP = response.getReturnValue();
          component.set('v.isARP', isARP);
          if (isARP) {
            component.set('v.showAmbitSelection', false);
            component.set('v.recordId', inputAttributes.recordId);
          }
          resolve();
        } else {
          helper.executeError(component, helper, 'error', response.getError()[0].message);
          reject();
        }
      });
      $A.enqueueAction(action);
    });
  },

  arpFlowValidation: function(component, event, helper) {
    return new Promise((resolve, reject) => {
      if (component.get('v.isCorporates') && component.get('v.isARP')) {
        var inputAttributes = component.get('v.inputAttributes');
        var action = component.get('c.arpFlowValidation');
        action.setParams({
          'ahaId': inputAttributes.recordId
        });
        action.setCallback(this, function(response) {
          var state = response.getState();
          if (state === 'SUCCESS') {
            var resp = response.getReturnValue();
            if (resp.status === 'Success') {
              component.set('v.showRefreshGCP', false);
              resolve();
            } else if (resp.status === 'RefreshGCP') {
              helper.executeError(component, helper, 'error', resp.message);
              component.set('v.showRefreshGCP', true);
              reject();
            } else if (resp.status === 'Error') {
              helper.executeError(component, helper, 'error', resp.message);
              reject();
            }
          } else {
            helper.executeError(component, helper, 'error', response.getError()[0].message);
            reject();
          }
        });
        $A.enqueueAction(action);
      } else {
        resolve();
      }
    });
  },

  checkIs2012P1: function(component, event, helper) {

    return new Promise($A.getCallback((resolve, reject) => {
      var inputAttributes = component.get('v.inputAttributes');
      var action = component.get('c.is2012P1');
      action.setParams({
        'ahaId': inputAttributes.recordId,
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var is2012P1 = response.getReturnValue();
          component.set('v.is2012P1', is2012P1);
          if (is2012P1) {
            component.set('v.showAmbitSelection', false);
            component.set('v.recordId', inputAttributes.recordId);
          }
          resolve();
        } else {
          helper.executeError(component, helper, 'error', response.getError()[0].message);
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },

  eeffAuditedValidation: function(component, event, helper) {
    return new Promise($A.getCallback((resolve, reject) => {
      if (component.get('v.isCorporates')) {
        var inputAttributes = component.get('v.inputAttributes');
        var action = component.get('c.eeffAuditedValidation');
        action.setParams({
          'ahaId': inputAttributes.recordId
        });
        action.setCallback(this, function(response) {
          var state = response.getState();
          if (state === 'SUCCESS') {  
            var resp = response.getReturnValue();
            if (resp.status === 'Success') {
              component.set('v.showRefreshGCP', false);
              resolve();
            } else if (resp.status === 'RefreshGCP') {
              helper.executeError(component, helper, 'error', resp.message);
              component.set('v.showRefreshGCP', true);
              reject();
            } else if (resp.status === 'Error') {
              helper.executeError(component, helper, 'error', resp.message);
              reject();
            }
          } else {
            helper.executeError(component, helper, 'error', response.getError()[0].message);
            reject();
          }
        });
        $A.enqueueAction(action);
      } else {
        resolve();
      }
    }));
  }
});