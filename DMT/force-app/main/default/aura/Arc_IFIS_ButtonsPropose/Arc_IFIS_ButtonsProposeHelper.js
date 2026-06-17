({
  initComponent: function(component, event, helper) {
    helper.initDelegation(component, event, helper)
      .then(() => helper.checkIsRTC(component, event, helper))
      .then(() => helper.checkPermission(component, event, helper))
      .then(() => helper.validatePS(component, event, helper))
      .then(() => helper.dataQuality(component, event, helper))
      .catch(errorMessage => helper.executeError(component, helper, 'toast', errorMessage))
      .finally(() => {
        component.set('v.isLoading', false);
        component.set('v.isInitalLoading', false);
      });
  },

    initDelegation: function(component, event, helper) {
      const actionName = 'initDelegation';
      const actionParams = { ahaId: component.get('v.ahaId') };

      return helper.promise(component, actionName, actionParams)
      .then(result => {
        const resp = JSON.parse(result);
        if (resp.success && resp.data && resp.data.recalculateRating !== 'Show') {
          return Promise.reject(resp.data.recalculateRating);
        } else if (resp.codStatus !== 200) {
          return Promise.reject(resp.msgInfo);
        } else {
          component.set('v.isRatingCalculated', true);
          component.set('v.delegationWrapper', resp);
        }
      });
    },

    checkPermission: function(component, event, helper) {
      const actionName = 'getPermissionOverlay';
      const actionParams = { recordId: component.get('v.ahaId') };
  
      return helper.promise(component, actionName, actionParams)
        .then(result => {
          if (result !== 'Show') {
            component.set('v.show', false);
            helper.warning(result, { duration: 5000 });
            return Promise.reject();
          }
        });
    },
  
    checkIsRTC: function(component, event, helper) {
      const actionName = 'fieldsValidation';
      const actionParams = { analysisId: component.get('v.delegationWrapper').analysisId };
  
      return helper.promise(component, actionName, actionParams)
        .then(result => {
          if (!result) {
            component.set('v.show', true);
            return Promise.reject();
          }
        });
    },
  
    dataQuality: function(component, event, helper) {
      const actionName = 'dataQualityValidation';
      const actionParams = { ahaId: component.get('v.ahaId') };
  
      return helper.promise(component, actionName, actionParams)
        .then(result => {
          const resp = JSON.parse(result);
          if (resp && resp.status && resp.status !== 'Success') {
            return Promise.reject(resp.message);
          }
        });
    },
  
    validatePS: function(component, event, helper) {
      const actionName = 'validateParentSubsidiary';
      const actionParams = { ahaId: component.get('v.ahaId') };
  
      return helper.promise(component, actionName, actionParams)
        .then(result => {
          component.set('v.show', true);
          component.set('v.showPropose', result.status !== 'Error');
          component.set('v.showPsRefresh', result.status === 'RefreshPS');
          if (result.status !== 'Success') {
            helper.executeError(component, helper, 'error', result.message);
          }
      });
  },

  proposeRating: function(component, event, helper) {
    var wrapper = component.get('v.delegationWrapper');
    var action = component.get('c.proposeRating');
    action.setParams({
      analysisId: wrapper.analysisId,
      selectedAmbit: component.get('v.selectedOption'),
      userId: component.get('v.selectedOptionUser')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = JSON.parse(response.getReturnValue());
        if (resp.status === 'true') {
          component.set('v.modalStep', '2');
          helper.refreshComponents();
        } else {
          helper.executeError(component, helper, 'error', resp.message);
        }
      } else {
        helper.executeError(component, helper, 'error', response.getError()[0].message);
      }
      component.set('v.isLoading', false);
    });
    $A.enqueueAction(action);
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
      helper.error(msgError, { duration: 5000 });
      helper.cancelAction(component);
    } else if (type === 'error') {
      component.set('v.showErrorSection', true);
      component.set('v.errorMessage', msgError);
    }
  },

  refreshComponents: function() {
    window.setTimeout($A.getCallback(function() {
      window.location.reload();
    }), 2500);
  },

  refreshPS: function(component, event, helper) {
    var action = component.get('c.refreshParentSubsidiary');
    action.setParams({
      'ahaId': component.get('v.ahaId')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = response.getReturnValue();
        if (resp.status === 'Success') {
          helper.success('Parent Subsidiary data was successfuly retrieved!', { duration: 5000 });
          helper.refreshComponents();
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
      component.set('v.isLoading', false);
    });
    $A.enqueueAction(action);
  },

  fetchAmbit: function(component, event, helper) {
    var action = component.get('c.fetchRegionLevel');
    var inputAttributes = component.get('v.ahaId');
    action.setParams({
      region: component.get('v.selectedRegion'),
      level: component.get('v.selectedLevel'),
      accHasAnalysisId: inputAttributes

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
      component.set('v.isLoading', false);
    });
    $A.enqueueAction(action);
  },

  fetchLevel: function(component, event, helper) {
    var action = component.get('c.fetchRegionLevel');
    var inputAttributes = component.get('v.ahaId');
    action.setParams({
      region: component.get('v.selectedRegion'),
      level: component.get('v.selectedLevel'),
      accHasAnalysisId: inputAttributes

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
      component.set('v.isLoading', false);
    });
    $A.enqueueAction(action);
  }
});