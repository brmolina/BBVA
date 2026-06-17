({
  initComponent: function(component, event, helper) {
    helper.getRatingData(component, event, helper)
      .then(() => helper.getRatingData(component, event, helper))
      .then(() => helper.dataQuality(component, event, helper))
      .catch((errorMessage) => helper.executeError(component, event, helper, errorMessage))
      .finally(() => {
        component.set('v.isLoading', false);
        component.set('v.isInitialLoading', false);
      });
  },

    getRatingData: function(component, event, helper) {
      const actionName = 'getRatingData';
      const actionParams = { ahaId: component.get('v.ahaId') };

      return helper.promise(component, actionName, actionParams)
      .then(function(result) {
        var respData = result.data;
        let proposeUserId = respData.proposeUser;
        component.set('v.proposeUserId', proposeUserId);
        if (result.success) {
          console.log('result.financialType es : ' + respData.financialType);
          component.set('v.ratingId', respData.ratingId);
          component.set('v.subProcessType', respData.subProcessType);
          component.set('v.wkfType', respData.wfType);
          component.set('v.geoOptions', respData.lstRegion);
          component.set('v.finType', respData.financialType);
          if (respData.recalculateRating === 'Show') {
            component.set('v.showModal', true);
          } else {
            component.set('v.showModal', false);
            helper.error(respData.recalculateRating, { duration: 5000 });
          }

          var ApiValueCRP = $A.get('$Label.arce.Arc_Gen_NewRaipOverrideApi');
          if (respData.wfType === ApiValueCRP) {
            component.set('v.entityOptions', [
              { label: 'Risk committee', value: 'COMITE' },
              { label: 'User', value: 'user' }
            ]);
          }
          if (
            respData.wfType === ApiValueCRP ||
            respData.ffssCertification === 'PROFORMA' ||
            respData.ffssCertification === 'PRO_FORMA_MERGER' ||
            respData.ffssCertification === 'PRO_FORMA_ACQUISITION' ||
            respData.withOverride === '1'
          ) {
            component.set('v.blockedEntity', true);
            component.set('v.entity', 'COMITE');
          } else {
            let difrntRatings = respData.showValidatedBy;
            let currentUserId = $A.get('$SObjectType.CurrentUser.Id');
            if (difrntRatings || proposeUserId === currentUserId) {
              component.set('v.showValidatedBy', true);
              component.set('v.entity', 'user');
              component.set('v.selectedUserId', currentUserId);
            } else if (!difrntRatings && proposeUserId !== currentUserId) {
              component.set('v.showUserDetls', false);
              component.set('v.entity', 'user');
              component.set('v.selectedUserId', currentUserId);
            }
          }
        } else {
          component.set('v.success', false);
          component.set('v.showModal', true);
          component.set('v.errorMessage', resp.message);
        }
        component.set('v.success', result.success);
      });
    },
  
    dataQuality: function(component, event, helper) {
      const actionName = 'dataQualityValidation';
      const actionParams = { ahaId: component.get('v.ahaId') };
  
      return helper.promise(component, actionName, actionParams)
        .then((result) => {
          const resp = JSON.parse(result);
          if (resp && resp.status && resp.status !== 'Success') {
            helper.closeModal(component);
            helper.error(resp.message, { duration: 5000 });
            return Promise.reject(resp.message);
          } else {
            component.set('v.showModal', true);
          }
      });
  },

  fetchUsers: function(component, ambitId) {
    var action = component.get('c.fetchUsersAha');

    action.setParams({
      selectedAmbit: ambitId,
      aHaId: component.get('v.recordId')
    });

    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = response.getReturnValue();
        var respData = resp.data;
        if (resp.success) {
          component.set('v.userOptions', respData.userList);
        } else {
          component.set('v.errorMessage', resp.message);
        }
        component.set('v.success', resp.success);
      } else {
        component.set('v.showModal', false);
        this.error(response.getError()[0].message, {});
      }
      component.set('v.isLoading', false);
    });
    $A.enqueueAction(action);
  },

  validateRating: function(component, event, helper) {
    const proposeUserId = component.get('v.proposeUserId');
    const selectedEntity = component.get('v.entity');
    const selectedUserId = component.get('v.selectedUserId');

    if (proposeUserId === selectedUserId && selectedEntity === 'user') {
      helper.error($A.get('{!$Label.arce.Arc_IFIS_FourEyesError}'), {});
      component.set('v.isLoading', false);
      return;
    }

    const selectedAha = component.get('v.ahaId');
    const paramsMap = {
      ahaId: selectedAha,
      ratingId: component.get('v.ratingId'),
      validatedById: component.get('v.selectedUserId'),
      description: component.get('v.validateDescr'),
      ambit: component.get('v.selectedAmbitId')
    };
    const valDataJson = JSON.stringify(paramsMap);

    helper.promise(component, 'callRatingPersistence', { ahaId: selectedAha })
      .then((persistenceResult) => {
        if (!persistenceResult.success) {
          return Promise.reject(persistenceResult.message);
        }
        return helper.promise(component, 'callRatingValidation', { valDataJson: valDataJson });
      })
      .then((validationResult) => {
        if (!validationResult.success) {
          return Promise.reject(validationResult.message);
        }
        return helper.promise(component, 'callRatingClone', { valDataJson: valDataJson });
      })
      .then((cloneResult) => {
        if (!cloneResult.success) {
          component.set('v.errorMessage', cloneResult.message);
          helper.error(cloneResult.message, {});
          return null;
        }
        return helper.promise(component, 'callFinalizeRating', { valDataJson: valDataJson });
      })
      .then((finalizeResult) => {
        if (!finalizeResult) {
          return;
        }
        if (!finalizeResult.success) {
          component.set('v.errorMessage', finalizeResult.message);
          helper.error(finalizeResult.message, {});
          return;
        }
        helper.success($A.get('{!$Label.arce.Arc_IFIS_BtnValidate_Success}'), {
          duration: 2500,
          title: 'Success'
        });
        helper.refreshTab(component);
        helper.closeModal(component);
      })
      .catch((errorMessage) => {
        component.set('v.success', false);
        helper.closeModal(component);
        helper.error(errorMessage, {});
      })
      .finally(() => {
        component.set('v.completed', true);
        component.set('v.isLoading', false);
      });
    },

  closeModal: function(component) {
    component.set('v.showModal', false);
    component.destroy();
  },

  refreshTab: function() {
    window.setTimeout($A.getCallback(function() {
      window.location.reload();
    }), 2500);
  },

  executeError: function(component, event, helper, errorMessage) {
    // Check if errorMessage is an object and has a property 'message'
    if (typeof errorMessage === 'object' && errorMessage.message) {
      errorMessage = errorMessage.message;
    }

    if (errorMessage !== 'No further action required') {
      helper.closeModal(component);
      helper.error(errorMessage, { duration: 5000 });
    }
  },

  fetchLevel: function(component, event, helper) {
    var action = component.get('c.fetchRegionLevel');
    action.setParams({
      region: component.get('v.selectedRegion'),
      level: component.get('v.selectedLevel'),
      accHasAnalysisId: component.get('v.recordId')

    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = JSON.parse(response.getReturnValue());
        if (resp.codStatus === 200) {
          component.set('v.levelOptions', resp.lstLevel);
        } else if (resp.codStatus === 500) {
          helper.executeError(component, event, helper, resp.msgInfo);
        }
      } else {
        component.set('v.isRatingCalculated', false);
        helper.executeError(component, event, helper, response.getError()[0].message);
      }
      component.set('v.spinnerStatus', false);
    });
    $A.enqueueAction(action);
  },

  fetchAmbit: function(component, event, helper) {
    var action = component.get('c.fetchRegionLevel');
    action.setParams({
      region: component.get('v.selectedRegion'),
      level: component.get('v.selectedLevel'),
      accHasAnalysisId: component.get('v.recordId')

    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = JSON.parse(response.getReturnValue());
        if (resp.codStatus === 200) {
          component.set('v.ambitOptions', resp.lstAmbits);
        } else if (resp.codStatus === 500) {
          helper.executeError(component, event, helper, resp.msgInfo);
        }
      } else {
        component.set('v.isRatingCalculated', false);
        helper.executeError(component, event, helper, response.getError()[0].message);
      }
      component.set('v.spinnerStatus', false);
    });
    $A.enqueueAction(action);
  },
});