({
  onInit: function(component19, event, helper) {

    // Get the empApi component
    component19.set('v.subscription', null);
    const empApi = component19.find('empApi');
    empApi.setDebugFlag(true);

    // Register error listener and pass in the error handler function
    empApi.onError($A.getCallback(error => {
      // Error can be any type of error (subscribe, unsubscribe...)
      console.error('EMP API error: ', error);
    }));
    helper.callbackSuscribe(component19, event, helper);

    // Check whether to resume RAIP.
    var arceIdToResume = component19.get('v.arceIdToResume');
    var resumeArce = arceIdToResume !== '';

    helper.setLoading(component19, true);

    if (resumeArce) {
      // Component invoked from RAIP (resume). Actions: Check config, get RAIP data, call persistence and run wizard.
      let initialProm = helper.checkInitConfigs(component19, event, helper);
      initialProm.then(function() {
        return helper.getRaipData(component19);
      }).then(function() {
        helper.setWizardSteps(component19);
        return helper.callPersistenceService(component19, helper);
      }).then(function() {
        helper.initStep(component19, event, helper);
      }).catch(function() {
        // Check if ARCE has been created. If so, there was an error in the persistence call.
        helper.catchError(component19, helper);
      });
    } else {
      // Component invoked from wizard (new). Actions: Check config, create RAIP, call persistence and run wizard.
      let initialProm = helper.checkInitConfigs(component19, event, helper);
      initialProm.then(function() {
        helper.setWizardSteps(component19);
        return helper.newRaip(component19);
      }).then(function() {
        helper.updateAhaExtension(component19, helper);
        return helper.createModifier(component19, helper);
      }).then(function() {
        return helper.callParentSubsidiary(component19, helper);
      }).then(function() {
        return helper.callPersistenceService(component19, helper);
      }).then(function() {
        helper.initStep(component19, event, helper);
      }).catch(function(e) {
        helper.setLoading(component19, false);
        console.log('EL ERROR -> ' + e);
        helper.catchError(component19, helper);
      });
    }
  },
  createModifier: function(component, helper) {
    var action = component.get('c.createModifier');
    var ahaId = component.get('v.accHasAnalysisId');
    action.setParams({
      ahaId
    });

    return this.promisifyAndCallAction(action);
  },
  updateAhaExtension: function(component, helper) {
    var action = component.get('c.updateAha');
    var ahaId = component.get('v.accHasAnalysisId');
    action.setParams({
      ahaId
    });

    return this.promisifyAndCallAction(action);
  },
  callParentSubsidiary: function(component, helper) {
    var action = component.get('c.callParentSubsidiary');
    var ahaId = component.get('v.accHasAnalysisId');
    action.setParams({
      ahaId
    });

    return this.promisifyAndCallAction(action);
  },
  checkInitConfigs: function(component, event, helper) {
    const getOptionsWf = helper.getLabelCombo(component, event, helper);
    const getOptionsMdl = helper.getMdlOptns(component, event, helper);
    return Promise.all([getOptionsWf, getOptionsMdl])
      .then(function(responses) {
        const optionsWf = responses[0];
        const optionsModls = responses[1];

        component.set('v.options', optionsWf);
        component.set('v.optionsMdls', optionsModls);
        if (optionsModls.length) {
          component.set('v.currentStep', 'suggestedFlow');
          helper.changeSubtitle(component);
          helper.setProgressStep(component, 'suggestedFlow');
          helper.enableNextButton(component, true);
        }
      });
  },
  initStep: function(component, event, helper) {
    component.set('v.initialized', true);
    helper.setLoading(component, false);
    helper.changeSubtitle(component);
    helper.hideBackButton(component);
    helper.enableNextButton(component, true);
  },
  getMdlOptns: function(component, event, helper) {
    const getOptions = component.get('c.model2012Active');
    getOptions.setParams({
      raipType: 'AnalysisCorp'
    });
    return helper.promisifyAndCallAction(getOptions);
  },
  isDisableNext: function(component, helper) {
    if (component.get('v.isDisabled')) {
      helper.enableNextButton(component, false);
    }
  },
  modlSelection: function(component, event, helper) {
    const getOptionsWf = helper.getLabelCombo(component, event, helper);
    getOptionsWf.then(function(optns) {
      component.set('v.options', optns);
      helper.enableNextButton(component, true);
    }).catch($A.getCallback(function() {
      helper.setLoading(component, false);
      helper.showError(component, $A.get('{!$Label.c.Lc_arce_NewARCE_UnexpectedError}'));
    }));
  },
  getLabelCombo: function(component, event, helper) {
    helper.enableNextButton(component, false);
    let prom;
    let profSet = component.get('v.profilingSet');
    if (profSet && profSet !== 'false') {
      const getLabCombo = component.get('c.picklistValueOfSelectWf');
      getLabCombo.setParams({
        'modelSelected': component.get('v.modlSlctd'),
        'profilingResult': component.get('v.profilingSet')
      });
      prom = this.promisifyAndCallAction(getLabCombo);
    } else {
      prom =  Promise.resolve('empty');
    }

    return prom;
  },
  enableNextButton: function(component, enabled) {
    const wzrdEvent = component.getEvent('wizardEvent');
    wzrdEvent.setParams({
      eventType: 'nextEnable',
      parameters: { enabled }
    });
    wzrdEvent.fire();
  },
  hideBackButton: function(component) {
    const wzrdEvent = component.getEvent('wizardEvent');
    wzrdEvent.setParams({
      eventType: 'hideBack',
      parameters: { hidden: true }
    });
    wzrdEvent.fire();
  },
  setLoading: function(component, loading) {
    component.set('v.loading', loading);
  },
  newRaip: function(component) {
    const helper = this; // eslint-disable-line

    // Call server action.
    let recordId = component.get('v.recordId');
    let actualClient = component.get('v.actualClient');
    let typeSelctd = component.get('v.typeSelected');
    let newanalysis = component.get('c.setanalysis');

    let params = {
      'recordId': recordId,
      'isorphan': 'false',
      'orphanNumber': '',
      'accounts': '[]',
      'analysisType': '4',
      'actualClient': actualClient.accNumber,
      'typeSelected': typeSelctd,
      'isCorp': 'true'
    };
    newanalysis.setParams({
      data: params
    });

    return this.promisifyAndCallAction(newanalysis)
      .then(function(result) {
        var resp = JSON.parse(result);
        if (resp.status === 'NUEVO') {
          component.set('v.existentAnalysis', false);
        } else if (resp.status === 'EXISTENTE') {
          component.set('v.existentAnalysis', true);
        }
        component.set('v.clientNumber', resp.clientnumber);
        component.set('v.analysisId', resp.analysisId);
        component.set('v.accHasAnalysisId', resp.accAnalyGpId);
      })
      .catch(function(errors) {
        helper.showError(component, errors[0].message);
        $A.get('e.force:closeQuickAction').fire();
        throw new Error('Execution failed');
      });
  },
  callPersistenceService: function(component, helper) {
    var action = component.get('c.callPersistence');
    var analysisId = component.get('v.analysisId');
    var customerId = component.get('v.customerId');
    action.setParams({
      analysisId, customerId
    });

    return this.promisifyAndCallAction(action);
  },
  handleFfssNext: function(component, event, helper) {
    helper.consultEngine(component, event, helper)
      .then(function() {
        helper.setRatingTool(component, helper);
        component.set('v.loading', true);
        return helper.evtUpdateBalances(component);
      })
      .then(function() {
        component.set('v.loading', true);
        return helper.consultFSdetails(component, event, helper);
      })
      .then(function() {
        helper.handleToolNext(component, helper);
        component.set('v.loading', true);
      })
      .catch(function(reject) {
        helper.showError(component, $A.get('{!$Label.c.Lc_arce_NewARCE_UnexpectedError}'));
        helper.setLoading(component, false);
      });
  },
  consultEngine: function(component, event, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      if (component.get('v.formDataMap.arce__RAR_rating_tool_id__c') !== '2021RTC_NFI') {
        var listIDS = component.get('v.selectedRows2');
        var eeffList = component.get('v.acctList');
        var msg = '';
        var errorMsg = '';
        let errorMessage;
        component.set('v.msgTable', msg);
        component.set('v.errorMsgTable', errorMsg);
        component.set('v.loading', true);

        var action = component.get('c.callEngineFinancialState');
        action.setParams({
          recordId: component.get('v.accHasAnalysisId'),
          updatedEEFF: eeffList,
          financialIdList: listIDS,
          isRAIP: true,
          isFinancialRAIP: component.get('v.isFinancialRAIP'),
          ratingToolSelect: null
        });
        action.setCallback(this, function(response) {
          var state = response.getState();
          if (state === 'SUCCESS') {
            if (listIDS.length === 0) {
              component.set('v.msgTable', 'no');
              component.set('v.errorMsgTable', $A.get('{!$Label.c.Arc_Gen_NotEEFF}'));
            } else {
              var resp = response.getReturnValue();
              if (resp.ratiosStatus === 'Success') {
                msg = 'si';
                component.set('v.ffssValid', resp.ratingValidFFSS);
                component.set('v.fsServiceId', resp.fsServiceId);
              }
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
        });
        $A.enqueueAction(action);
      } else {
        resolve();
      }
    }));
  },
  consultFSdetails: function(component, event, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var action = component.get('c.consultFSdetails');
      action.setParams({
        recordId: component.get('v.accHasAnalysisId'),
        fsServiceId: component.get('v.fsServiceId')
      });
      action.setCallback(this, function(response) {
        if (response.getState() === 'SUCCESS') {
          let resp = response.getReturnValue();
          helper.controlErrors(component, helper, event, resp);
          resolve();
        } else {
          var errors = response.getError();
          var errorMsg = (errors[0] && errors[0].message) ? errors[0].message : $A.get('{!$Label.c.Cls_arce_GRP_servError}');
          helper.toastMessage(component, event, 'ERROR', 'Error: ' + errorMsg);
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  evtUpdateBalances: function(component) {
    var cmpEventTrue = component.getEvent('updateBlances');
    cmpEventTrue.setParams({
      'updatedRatios': 'true'
    });
    cmpEventTrue.fire();
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
  setRatingTool: function(component, helper) {
    component.set('v.ratingTool', component.get('v.formDataMap').arce__RAR_rating_tool_id__c);
  },
  handleToolNext: function(component, helper) {
    helper.setLoading(component, true);
    const persistance = helper.persistData(component);
    persistance.then(function() {
      helper.redirectToArce(component, component.get('v.analysisId'), true);
      helper.unsubscribe(component);
    }).catch(function() {
      helper.showError(component, $A.get('{!$Label.c.Lc_arce_NewARCE_UnexpectedError}'));
      helper.setLoading(component, false);
    });
  },
  persistData: function(component, event) {
    var helper = this;  // eslint-disable-line
    var action = component.get('c.persistRatingModel');
    action.setParams({
      'accHasAnalysisId': component.get('v.accHasAnalysisId'),
      'ratingModelValue': component.get('v.ratingTool'),
      'raipType': component.get('v.ratingType'),
      'triageConfig': component.get('v.rtngToolType')
    });

    return this.promisifyAndCallAction(action)
      .then(function(result) {
        const res = JSON.parse(result);
        const toastEvent = $A.get('e.force:showToast');
        if (res.saveStatus === 'true') {
          component.set('v.analysisId', res.analysisId);
          toastEvent.setParams({
            'title': $A.get('{!$Label.c.Lc_arce_newAnalysisSuccess}'),
            'type': 'success',
            'duration': '8000',
            'message': ''
          });
          toastEvent.fire();
        } else {
          helper.showError(component, $A.get('{!$Label.c.Lc_arce_NewARCE_UnexpectedError}'));
          $A.get('e.force:closeQuickAction').fire();
          throw new Error($A.get('{!$Label.c.Lc_arce_NewARCE_UnexpectedError}'));
        }
      });
  },
  redirectToArce: function(component, arceId, arceInScope, riskSegment) {
    const wzrdEvent = component.getEvent('wizardEvent');
    wzrdEvent.setParams({
      eventType: 'redirectToArce',
      parameters: { arceId, arceNotInScope: !arceInScope, riskSegment }
    });
    wzrdEvent.fire();
  },
  getRaipData: function(component28) {
    // Get RAIP data for existing ARCE.
    var action = component28.get('c.getRAIPData');

    action.setParams({
      analysisId: component28.get('v.arceIdToResume')
    });

    return this.promisifyAndCallAction(action)
      .then(function(result) {
        const outputJson = JSON.parse(result);
        const serviceResponse = JSON.parse(outputJson.serviceMessage);
        component28.set('v.analysisId', serviceResponse.analysisId);
        component28.set('v.accHasAnalysisId', serviceResponse.accHasAnalysisId);
        component28.set('v.customerId', serviceResponse.customerId);
      });
  },
  changeIRPType: function(component29, event, helper) {
    let selectedIrp = component29.get('v.RAIPSelectComboValue');
    component29.set('v.irpTypeSlctd', selectedIrp);
    let rarRatingTool = component29.get('v.IRPRarRatingTool');
    if (selectedIrp === $A.get('{!$Label.arce.Arc_Gen_NewRaipOverrideApi}') && rarRatingTool) {
      helper.enableNextButton(component29, true);
    } else if (selectedIrp === $A.get('{!$Label.arce.Arc_Gen_NewRaipAdjustmentApi}') || selectedIrp === $A.get('{!$Label.arce.Arc_Gen_NewRaipRatingApi}')) {
      helper.enableNextButton(component29, true);
    } else if (selectedIrp === $A.get('{!$Label.arce.Arc_Gen_NewRaipOverrideApi}')) {
      helper.enableNextButton(component29, false);
    }
  },
  catchError: function(component30, helper) {
    helper.setLoading(component30, false);
    const arceId = component30.get('v.analysisId');
    if (arceId) {
      helper.showError(component30, $A.get('{!$Label.c.Arc_Gen_RAIP_ErrorCreationOrPersistence}'));
    } else {
      helper.showError(component30, $A.get('{!$Label.c.Lc_arce_NewARCE_UnexpectedError}'));
    }
  },
  showError: function(component31, message) {
    const wzrdEvent = component31.getEvent('wizardEvent');
    wzrdEvent.setParams({
      eventType: 'showError',
      parameters: { error: message }
    });
    wzrdEvent.fire();
  },
  handleWFV2Next: function(component, event, helper) {
    const wfSelected = component.get('v.RAIPSelectComboValue');
    if (wfSelected === $A.get('{!$Label.arce.Arc_Gen_NewRaipRatingApi}') || wfSelected === 'EXPG') {
      if (wfSelected === 'EXPG' && component.get('v.renovationFind')) {
        helper.setProgressStep(component, 'renovationRTC');
        helper.setRatingTool(component, helper);
        component.set('v.ratingTool', '2021RTC_EXPG');
        helper.handlerenovationNext(component, event, helper);
      } else {
        //Si es Seleccionado IRP
        const alertEEFF = $A.get('$Label.c.Arce_Gen_MsgEEFFLessHundredMil');
        component.set('v.warningEEFF', alertEEFF.split('<br>'));
        component.set('v.currentStep', 'ffss');
        helper.setProgressStep(component, 'ffss');
        const updtIrpWf = helper.irpWfUpdt(component);
        updtIrpWf.then($A.getCallback(function() {
          helper.changeSubtitle(component);
          helper.setWizardSteps(component);
        })).catch($A.getCallback(function() {
          helper.showError(component, $A.get('{!$Label.c.Lc_arce_NewARCE_UnexpectedError}'));
          helper.setLoading(component, false);
        }));
      }
    } else {
      //Si es Seleccionado ARP o CRP
      component.set('v.ratingTool', component.get('v.modlSlctd') ? component.get('v.modlSlctd').concat(component.get('v.irpTypeSlctd')) : component.get('v.irpTypeSlctd'));
      const ffssWAhas = helper.newFFSSWAhas(component);
      ffssWAhas.then(function() {
        helper.setProgressStep(component, 'redirectToArce');
        helper.handleToolNext(component, helper);
      }).catch(function(e) {
        console.log('ERROR handleWFV2Next --> ' + e);
        helper.showError(component, $A.get('{!$Label.c.Lc_arce_NewARCE_UnexpectedError}'));
        helper.setLoading(component, false);
      });
    }
  },
  irpWfUpdt: function(component) {
    var action = component.get('c.irpWfUpdt');
    action.setParams({
      'accHasAnalysisId': component.get('v.accHasAnalysisId'),
      'flowSelected': component.get('v.RAIPSelectComboValue')
    });
    return this.promisifyAndCallAction(action);
  },
  newFFSSWAhas: function(component) {
    var action = component.get('c.newFFSSWAhas');
    action.setParams({
      'accHasAnalysisId': component.get('v.accHasAnalysisId'),
      'analysisId': component.get('v.analysisId'),
      'flowSelected': component.get('v.RAIPSelectComboValue'),
      'rarRatingTool': component.get('v.IRPRarRatingTool')
    });
    return this.promisifyAndCallAction(action);
  },

  // Methods to control the view when move forward in the wizard.
  nextStep: function(component, event, helper) {
    const currentStep = component.get('v.currentStep');
    switch (currentStep) {
      case 'ffss': {
        component.set('v.currentStep', 'ffss');
        helper.setProgressStep(component, 'redirectToArce');
        helper.handleFfssNext(component, event, helper);
        break;
      }
      case 'suggestedFlow': {
        helper.changeSubtitle(component);
        if (component.get('v.formDataMap.arce__RAR_rating_tool_id__c') === '2021RTC_EXPG') {
          component.set('v.currentStep', 'explicitGuaranteeselector');
          helper.setProgressStep(component, 'explicitGuaranteeselector', helper);
          helper.enableNextButton(component, true);
          helper.changeSubtitle(component);
          helper.setLoading(component, false);
          helper.handleTriageNext(component, event, helper);
        } else {
          helper.setProgressStep(component, 'renovationRTC');
          helper.setRatingTool(component, helper);
          helper.handlerenovationNext(component, event, helper);
        }
        break;
      }
      case 'renovationRTC': {
        helper.handleCorpRenwNext(component, event, helper);
        break;
      }
      case 'explicitGuaranteeselector': {
        helper.changeSubtitle(component);
        helper.setRatingTool(component, helper);
        helper.handleExpGuaranteeNext(component, event, helper);
        break;
      }
    }
  },
  changeSubtitle: function(component) {
    const wzrdEvent = component.getEvent('wizardEvent');
    const currentStep = component.get('v.currentStep');
    var subtitleText = '';

    switch (currentStep) {
      case 'ffss':
        subtitleText = $A.get('{!$Label.c.Arc_Gen_Analysis_ST_FFSS}');
        break;
      case 'suggestedFlow':
        subtitleText = $A.get('{!$Label.c.Arc_Gen_RTC_Flow_Suggested}');
        break;
      case 'explicitGuaranteeselector':
        subtitleText = 'Explicit Guarantee Selector';
        break;
      case 'renovationRTC':
        subtitleText = 'Renovation RTC';
        break;
    }

    wzrdEvent.setParams({
      eventType: 'showSubtitle',
      parameters: { text: subtitleText }
    });

    wzrdEvent.fire();
  },
  setWizardSteps: function(component) {
    // List of steps.
    const ffssStep = { label: $A.get('{!$Label.c.Arc_Gen_Analysis_ST_FFSS}'), value: 'ffss' };
    const suggestedFlow = { label: $A.get('{!$Label.c.Arc_Gen_RTC_Flow_Suggested}'), value: 'suggestedFlow' };
    const explicitGuaranteeselector = { label: 'Explicit Guarantee Selector', value: 'explicitGuaranteeselector' };
    const redirectToArceStep = { label: $A.get('{!$Label.c.Arc_Gen_Analysis_ST_RedirectToARCE}'), value: 'redirectToArce' };

    var steps = [suggestedFlow, explicitGuaranteeselector, ffssStep, redirectToArceStep];

    /* Fire event. */
    const wzrdEvent = component.getEvent('wizardEvent');
    wzrdEvent.setParams({
      'eventType': 'setProgressSteps',
      parameters: { steps }
    });
    wzrdEvent.fire();
  },
  setProgressStep: function(component, step) {
    const wzrdEvent = component.getEvent('wizardEvent');
    wzrdEvent.setParams({
      eventType: 'setCurrentProgressStep',
      parameters: { step }
    });
    wzrdEvent.fire();
  },

  //Method to centralize every call made.
  promisifyAndCallAction: function(action) {
    return new Promise($A.getCallback((resolve, reject) => {
      action.setCallback(this, function(response) {
        const status = response.getState();
        if (status === 'SUCCESS') {
          const respValue = response.getReturnValue();

          if (respValue !== null && typeof respValue === 'object') {
            // Check whether response is a ServiceAndSaveResponse object.
            const serviceCode = respValue.serviceCode;
            const saveStatus = respValue.saveStatus;

            if (typeof serviceCode !== 'undefined' && !serviceCode.startsWith('2')) {
              reject(respValue.serviceMessage);
            } else if (saveStatus === 'false') {
              reject(respValue.saveMessage);
            } else {
              resolve(respValue);
            }
          } else {
            resolve(respValue);
          }
        } else {
          reject(response.getError());
        }
      });

      $A.enqueueAction(action);
    }));
  },
  callbackSuscribe: function(component, event, helper) {
    // Get the empApi component
    const empApi = component.find('empApi');
    const channel = component.get('v.channel');
    const replayId = -1;
    const callback = function(message) {
      console.log('Event Received : ' + JSON.stringify(message));
      helper.onReceiveNotification(component, message, helper);
    };

    // Subscribe to the channel and save the returned subscription object.
    empApi.subscribe(channel, replayId, callback).then(function(newSubscription) {
      console.log('Subscribed to channel ' + channel);
      component.set('v.subscription', newSubscription);
    });
  },
  unsubscribe: function(component) {
    const empApi = component.find('empApi');
    if (empApi) {
      const subscription = component.get('v.subscription');
      empApi.unsubscribe(subscription, $A.getCallback(unsubscribed => {
        component.set('v.subscription', null);
      }));
    }
  },
  onReceiveNotification: function(component, message, helper) {
    // Extract notification from platform event
    const newNotification = {
      time: $A.localizationService.formatDateTime(
        message.data.payload.CreatedDate, 'HH:mm'),
      message: message.data.payload.arce__Message__c
    };

    //Remove Arce to avoid future errors with Overlay
    helper.removeRecords(component);

    // Save notification in history
    const notifications = component.get('v.notifications');
    notifications.push(newNotification);
    component.set('v.notifications', notifications);
    component.set('v.isDisabled', true);

    // Display notification in a toast
    helper.showError(component, newNotification.message);
    $A.get('e.force:closeQuickAction').fire();
    helper.displayToast(component, 'ERROR', newNotification.message);
  },
  removeRecords: function(component) {
    var action = component.get('c.removeAnalysis');
    var ahaId = component.get('v.accHasAnalysisId');
    action.setParams({
      ahaId
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        console.log('::::::: Arce Removed');
      }
    });
    $A.enqueueAction(action);
  },
  displayToast: function(component, type, message) {
    const toastEvent = $A.get('e.force:showToast');
    toastEvent.setParams({
      type: type,
      message: message,
      duration: 5000
    });
    toastEvent.fire();
  },
  handleTriageNext: function(component, event, helper) {
    const modlSlctd = component.get('v.formDataMap.arce__RAR_rating_tool_id__c');
    switch (modlSlctd) {
      case '2021RTC_NFI':
        helper.handleNoFinInfo(component, event, helper);
        break;
      case '2021RTC_GEN': case '2021RTC_FS': case '2021RTC_GEN_NBF':
        helper.handleWFV2Next(component, event, helper);
        break;
      case '2021RTC_EXPG':
        component.set('v.currentStep', 'explicitGuaranteeselector');
        helper.enableNextButton(component, true);
        helper.changeSubtitle(component);
        break;
    }
  },
  handleNoFinInfo: function(component, event, helper) {
    helper.setLoading(component, true);

    const ffssWAhas = helper.newFFSSWAhas(component);
    ffssWAhas.then(function() {
      helper.handleToolNext(component, helper);
    }).catch(function(e) {
      console.log('ERROR newFFSSWAhas --> ' + e);
      helper.showError(component, $A.get('{!$Label.c.Lc_arce_NewARCE_UnexpectedError}'));
      helper.setLoading(component, false);
    });
  },
  handleExpGuaranteeNext: function(component, event, helper) {
    const modlSlctd = component.get('v.formDataMap.arce__RAR_rating_tool_id__c');
    if (modlSlctd === '2021RTC_GEN' || modlSlctd === '2021RTC_GEN_NBF') {
      helper.handleWFV2Next(component, event, helper);
    } else if (modlSlctd === '2021RTC_EXPG') {
      helper.handleNoFinInfo(component, event, helper);
    }
  },
  handlerenovationNext: function(component, event, helper) {
    helper.handleREV2Next(component, event, helper);
  },
  handleREV2Next: function(component, event, helper) {
    let checkPromise = helper.corpRenewRTC(component, helper);
    checkPromise.then($A.getCallback(function(dataWrapper) {
      if (dataWrapper.renew) {
        component.set('v.currentStep', 'renovationRTC');
        component.set('v.renovationFind', true);
        helper.setProgressStep(component, 'renovationRTC', helper);
        helper.setLoading(component, false);
        helper.changeSubtitle(component);
      } else {
        component.set('v.renovationFind', false);
        helper.enableNextButton(component, false);
        helper.handleTriageNext(component, event, helper);
      }
    })).catch($A.getCallback(function() {
      helper.showError(component, $A.get('{!$Label.c.Lc_arce_NewARCE_UnexpectedError}'));
    }));
  },
  corpRenewRTC: function(component, helper) {
    return new Promise($A.getCallback((resolve, reject) => {
      var action = component.get('c.getRenewableRTC');
      let actualClient = component.get('v.actualClient');
      let ratingtool = component.get('v.ratingTool');
      action.setParams({
        clientId: actualClient.accId,
        rarRating: ratingtool
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var responseWrapper = response.getReturnValue();
          component.set('v.dataCorp', JSON.parse(responseWrapper));
          resolve(JSON.parse(responseWrapper));
        } else {
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  handleCorpRenwNext: function(component, event, helper) {
    helper.setLoading(component, true);
    let isRenew = component.get('v.corpRenewal') === 'yes';
    if (isRenew) {
      component.set('v.currentStep', 'renovationRTC');
      helper.setProgressStep(component, 'renovationRTC', helper);
      helper.cloneRecordsRTC(component, helper);
    } else {
      component.set('v.currentStep', 'ffss');
      helper.setProgressStep(component, 'ffss', helper);
      helper.setLoading(component, false);
      const updtIrpWf = helper.irpWfUpdt(component);
      updtIrpWf.then($A.getCallback(function() {
        helper.changeSubtitle(component);
      })).catch($A.getCallback(function() {
        helper.setLoading(component, false);
        helper.showError(component, $A.get('{!$Label.c.Lc_arce_NewARCE_UnexpectedError}'));
      }));
    }
  },
  cloneRecordsRTC: function(component, helper) {
    return new Promise($A.getCallback((resolve, reject) => {
      var action = component.get('c.doCloneRecords');
      let current = component.get('v.accHasAnalysisId');
      let datacorp = component.get('v.dataCorp');
      let ratingtool = component.get('v.ratingTool') === '2021RTC_EXPG'  ? '2021RTC_GEN' : component.get('v.ratingTool');
      action.setParams({
        ahacurrent: current,
        data: JSON.stringify(datacorp),
        rarRating: ratingtool
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          helper.doCloneEEFF(component, helper, current, JSON.stringify(datacorp), ratingtool);
          resolve();
        } else {
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  doCloneEEFF: function(component, helper, current, datacorp, ratingtool) {
    var action = component.get('c.createEEFF');
    action.setParams({
      ahacurrent: current,
      data: datacorp,
      rarRating: ratingtool
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        helper.handleIrpWfV2(component, helper);
      } else {
        const errorMess = response.getError();
        helper.setLoading(component, false);
        helper.showError(component, errorMess[0].message);
        helper.handleToolNext(component, helper);
      }
    });
    $A.enqueueAction(action);
  },
  handleIrpWfV2: function(component, helper) {
    helper.setRatingTool(component);
  }
});