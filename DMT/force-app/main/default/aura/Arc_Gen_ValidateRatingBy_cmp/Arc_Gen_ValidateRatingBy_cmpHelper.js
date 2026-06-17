({

  // PUBLIC METHODS

  getArceConfigs: function(component, event, helper) {
    return helper._callApex(component, 'getArceConfigs', {});
  },
  isOverrideComplete: function(component, event, helper) {
    return helper._callApex(component, 'isOverrideComplete', { ahaId: component.get('v.recordId') })
      .then((result) => {
        const resp = result;
        component.set('v.isRTC', String(resp.isRTC).toLowerCase() === 'true');
        if (resp.status === 'Success') {
          return 'OK';
        } else {
          component.set('v.show', true);
          component.set('v.errorMessage', resp.message);
          return Promise.reject(resp.message);
        }
      });
  },
  dataQuality: function(component, event, helper) {
    if (component.get('v.isRTC')) {
      return helper._callApex(component, 'dataQuality', { ahaId: component.get('v.recordId') })
        .then((result) => {
          return helper._handleStatusResponse(component, result, 'RefreshGCP', 'showRefreshGCP');
        });
    }
    return Promise.resolve();
  },
  validatePS: function(component, event, helper) {
    if (component.get('v.isRTC')) {
      return helper._callApex(component, 'validateParentSubsidiary', { ahaId: component.get('v.recordId'), isTest: false })
        .then((result) => {
          return helper._handleStatusResponse(component, result, 'RefreshPS', 'showPsRefresh');
        });
    }
    return Promise.resolve();
  },
  isESGPersistanceActive: function(component, event, helper) {
    return helper._callApex(component, 'isPersistanceESGActive', {})
      .then((result) => {
        component.set('v.isESGActive', result);
      });
  },
  getSalesEngine: function(component, event, helper) {
    component.set('v.entityOptions', [
      { label: 'Committee', value: 'COMITE' },
      { label: 'User', value: 'user' }
    ]);
    return helper._callApex(component, 'getSalesEngine', { ahaId: component.get('v.recordId') })
      .then((result) => {
        if (result.calculationResult) {
          return 'OK';
        } else {
          if (result.message === 'Config Deactive') {
            return 'OK';
          } else if (result.code.includes('20')) {
            throw new Error($A.get('{!$Label.c.Arc_Gen_NoSalesEngine}'));
          } else {
            throw new Error($A.get('{!$Label.c.Arc_Gen_ErrorEngine}'));
          }
        }
      });
  },
  getRatingData: function(component) {
    var action = component.get('c.getRatingData');
    action.setParams({
      aHaId: component.get('v.recordId')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = response.getReturnValue();
        var respData = resp.data;
        let proposeUserId = respData.proposeUser;
        component.set('v.proposeUserId', proposeUserId);
        if (resp.success) {
          console.log('resp.financialType es : ' + respData.financialType);
          component.set('v.ratingId', respData.ratingId);
          component.set('v.subProcessType', respData.subProcessType); 
          component.set('v.wkfType', respData.wfType);
          component.set('v.geoOptions', respData.regionList);
          component.set('v.finType', respData.financialType);
          component.set('v.financialStatementId', respData.finStatementId);
          if (respData.recalculateRating == 'Show') {
            component.set('v.show', true);
          }else{
            component.set('v.show', false);
          	this.showToast('WARNING', respData.recalculateRating);
          }

          var ApiValueCRP = $A.get('$Label.arce.Arc_Gen_NewRaipOverrideApi');
          if(respData.wfType === ApiValueCRP) {
            component.set('v.entityOptions', [
              { label: 'Risk committee', value: 'COMITE' },
              { label: 'User', value: 'user' }
            ]);
          }
          if (
            respData.wfType === ApiValueCRP ||
            (
            component.get('v.isPROFORMAEnabled') && (
            respData.ffssCertification === 'PROFORMA' ||
            respData.ffssCertification === 'PRO_FORMA_MERGER' ||
            respData.ffssCertification === 'PRO_FORMA_ACQUISITION')) ||
            respData.withOverride ==='1'
          ) {
            component.set('v.blockedEntity', true);
            component.set('v.entity', 'COMITE');
          } else {
            let difrntRatings = respData.showValidatedBy;
            let currentUserId = $A.get("$SObjectType.CurrentUser.Id");
            if(difrntRatings || proposeUserId == currentUserId) {
              component.set('v.showValidatedBy', true);
              component.set('v.entity', 'user');
              component.set('v.selectedUserId', currentUserId);
            } else if (!difrntRatings && proposeUserId != currentUserId) {
              component.set('v.showUserDetls', false);
              component.set('v.entity', 'user');
              component.set('v.selectedUserId', currentUserId);
            }
          }
        } else {
          component.set('v.success', false);
          component.set('v.show', true);
          component.set('v.errorMessage', resp.message);
        }
        component.set('v.success', resp.success);
      } else {
        component.set('v.show', false);
        this.showToast('error', response.getError()[0].message);

        //$A.get('e.force:closeQuickAction').fire();

      }
      component.set('v.loading', false);
    });
    $A.enqueueAction(action);
  },
  preRatingScoreAlert: function(component, event, helper) {
    if (component.get('v.isRTC')) {
      return helper._callApex(component, 'preRatingScoreAlert', { ahaId: component.get('v.recordId') })
        .then((result) => {
          const respId = result;
          if (respId !== '') {
            component.set('v.alertLink', '/' + respId);
            component.set('v.showAlert', true);
            component.set(
              'v.alertMessage',
              $A.get('$Label.c.Arc_Gen_RatingAlert_Message')
            );
          }
        });
    }
    return Promise.resolve();
  },
  limitAdvisor: function(component, event, helper) {
    if (!helper._shouldCallLimitAdvisor(component)) {
      return Promise.resolve();
    }
    if (!helper._hasValidFinancialStatement(component)) {
      return Promise.resolve();
    }
    return helper._callApex(component, 'callLimitAdvisorSrv', { aHaId: component.get('v.recordId') })
      .then((result) => {
        const resp = result;
        if (!resp.success) {
          component.set('v.errorMessage', resp.message);
          return Promise.reject(resp.message);
        }
        return Promise.resolve();
      });
  },
  persistenceEsg: function(component, event, helper) {
    return helper._callApexWithErrorHandling(component, 'callPersistenceEsg', { ahaId: component.get('v.recordId') });
  },
  persistenceDataEsg: function(component, event, helper) {
    return helper._callApexWithErrorHandling(component, 'callPersistenceDataEsg', { ahaId: component.get('v.recordId') });
  },
  fetchUsers: function(component, event, helper, ambitId, recordId) {
    helper._callApex(component, 'fetchUsers', { selectedAmbit: ambitId, recordId: recordId })
      .then((result) => {
        const resp = result;
        const respData = resp.data;
        if (resp.success) {
          component.set('v.userOptions', respData.userList);
        } else {
          component.set('v.errorMessage', resp.message);
        }
        component.set('v.success', resp.success);
      })
      .catch((error) => {
        component.set('v.show', false);
        helper.showToast('error', error);
      })
      .finally(() => {
        component.set('v.loading', false);
      });
  },
  validating: function(component, event, helper) {
    return helper._callApex(component, 'validateRating', {
      analysisId: component.get('v.recordId'),
      ratingId: component.get('v.ratingId'),
      validatedById: component.get('v.entity') === 'COMITE' ? 'COMITE' : component.get('v.selectedUserId'),
      description: component.get('v.validateDescr'),
      ambit: component.get('v.selectedAmbitId')
    })
      .then((resp) => {
        if (!resp.success) {
          component.set('v.errorMessage', resp.message);
        }
        component.set('v.success', resp.success);
        component.set('v.completed', true);
      });
  },
  refreshPS: function(component, event, helper) {
    helper._callApex(component, 'refreshParentSubsidiary', { ahaId: component.get('v.recordId'), isTest: false })
      .then((result) => {
        const resp = result;
        if (resp.status === 'Success') {
          helper.showToast('success', 'Parent Subsidiary data was successfuly retrieved!');
          $A.get('e.force:refreshView').fire();
          component.destroy();
        } else {
          component.set('v.errorMessage', resp.message);
          component.set('v.showPsRefresh', true);
        }
      })
      .catch((error) => {
        component.set('v.errorMessage', error);
        component.set('v.showPsRefresh', true);
      });
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
  showToast: function(type, message) {
    var toastEventUE = $A.get('e.force:showToast');
    toastEventUE.setParams({
      title: '',
      type: type,
      mode: 'dismissible',
      duration: '7000',
      message: message,
    });
    toastEventUE.fire();
  },

  // PRIVATE METHODS

  _setBasicRatingData: function(component, respData) {
    component.set('v.ratingId', respData.ratingId);
    component.set('v.subProcessType', respData.subProcessType);
    component.set('v.wkfType', respData.wfType);
    component.set('v.ambitOptions', respData.ambitList);
    component.set('v.finType', respData.financialType);
    component.set('v.financialStatementId', respData.finStatementId);
  },
  _handleRecalculateRating: function(component, respData) {
    if (respData.recalculateRating === 'Show') {
      component.set('v.show', true);
    } else {
      component.set('v.show', false);
      this.showToast('WARNING', respData.recalculateRating);
    }
  },
  _configureEntityOptions: function(component, respData, proposeUserId) {
    const ApiValueCRP = $A.get('$Label.arce.Arc_Gen_NewRaipOverrideApi');
    if (respData.wfType === ApiValueCRP) {
      component.set('v.entityOptions', [
        { label: 'Risk committee', value: 'COMITE' },
        { label: 'User', value: 'user' },
      ]);
    }
    if (this._shouldBlockEntity(respData, ApiValueCRP)) {
      this._setBlockedEntityConfiguration(component);
    } else {
      this._setUserEntityConfiguration(component, respData, proposeUserId);
    }
  },
  _shouldBlockEntity: function(respData, ApiValueCRP) {
    return respData.wfType === ApiValueCRP ||
           respData.ffssCertification === 'PROFORMA' ||
           respData.ffssCertification === 'PRO_FORMA_MERGER' ||
           respData.ffssCertification === 'PRO_FORMA_ACQUISITION' ||
           respData.withOverride === '1';
  },
  _setBlockedEntityConfiguration: function(component) {
    component.set('v.blockedEntity', true);
    component.set('v.entity', 'COMITE');
  },
  _setUserEntityConfiguration: function(component, respData, proposeUserId) {
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
  },
  _handleStatusResponse: function(component, result, refreshStatus, showRefreshAttribute) {
    const resp = result;
    if (resp.status === 'Success') {
      component.set('v.show', true);
      component.set('v.' + showRefreshAttribute, false);
      return;
    } else if (resp.status === refreshStatus) {
      component.set('v.show', true);
      component.set('v.errorMessage', resp.message);
      component.set('v.' + showRefreshAttribute, true);
      throw new Error(resp.message);
    } else if (resp.status === 'Error') {
      component.set('v.show', true);
      component.set('v.errorMessage', resp.message);
      throw new Error(resp.message);
    }
  },
  _callApexWithErrorHandling: function(component, methodName, params) {
    return this._callApex(component, methodName, params)
      .then((result) => {
        const resp = result;
        if (!resp.success) {
          if (methodName === 'callPersistenceDataEsg') {
            component.set('v.errorMessage', resp.message);
          } else {
            console.log(resp.message);
          }
        } else if (methodName === 'callPersistenceDataEsg') {
          console.log('callPersistenceDataEsg OK');
        }
        return resp;
      })
      .catch((error) => {
        console.log(error);
        return Promise.reject(error);
      });
  },
  _shouldCallLimitAdvisor: function(component) {
    const workFlowIRP = component.get('v.wkfType');
    return workFlowIRP !== null &&
           workFlowIRP !== undefined &&
           workFlowIRP === 'IRP';
  },
  _hasValidFinancialStatement: function(component) {
    const financialStatementId = component.get('v.financialStatementId');
    return financialStatementId !== '' &&
           financialStatementId !== null &&
           financialStatementId !== undefined;
  },
  _callApex: function(component, methodName, params) {
    return new Promise(
      $A.getCallback(function(resolve, reject) {
        const action = component.get('c.' + methodName);
        if (Object.keys(params).length > 0) {
          action.setParams(params);
        }
        action.setCallback(this, function(response) {
          if (response.getState() === 'SUCCESS') {
            resolve(response.getReturnValue());
          } else {
            const errors = response.getError();
            const message = (errors && errors[0] && errors[0].message) || 'Unknown error';
            reject(message);
          }
        });
        $A.enqueueAction(action);
      })
    );
  },
  checkScoreAlert: function(component, event, helper) {
    return new Promise((resolve, reject) => {
      if (component.get('v.isRTC')) {
        var action = component.get('c.checkScoreAlert');
        action.setParams({
          'ahaId': component.get('v.recordId')
        });
        action.setCallback(this, function(response) {
          var state = response.getState();
          if (state === 'SUCCESS') {
            var respId = response.getReturnValue();
            if (respId !== '') {
              component.set('v.alertLink', '/' + respId);
              component.set('v.showAlert', true);
              component.set('v.alertMessage', $A.get('$Label.c.Arc_Gen_RatingAlert_Message_core'));
              resolve();
            }
          } else {
            this.showToast('error', response.getError()[0].message);
            resolve();
          }
        });
        $A.enqueueAction(action);
      } else {
        resolve();
      }
    });
  }
});