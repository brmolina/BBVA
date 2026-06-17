({
  onInit: function(component17, event, helper) {
    component17.set('v.subscription', null);
    component17.set('v.notifications', []);

    // Get the empApi component
    const empApi = component17.find('empApi');

    // Uncomment below line to enable debug logging (optional)
    empApi.setDebugFlag(true);

    // Register error listener and pass in the error handler function
    empApi.onError($A.getCallback(error => {
      // Error can be any type of error (subscribe, unsubscribe...)
      console.error('EMP API error: ', error);
    }));
    helper.callbackSuscribe(component17, event, helper);

    // Check whether to resume RAIP.
    var arceIdToResume = component17.get('v.arceIdToResume');
    var resumeArce = arceIdToResume !== '';

    // Check whether this component is invoked from the EEFF button.
    var changeFfssMode = component17.get('v.changeFfssMode');

    component17.set('v.initialized', false);
    helper.hideBackButton(component17);
    helper.enableNextButton(component17, false);
    helper.setLoading(component17, true);

    if (changeFfssMode) {
      // Component invoked from FFSS button. Actions: Check config and run wizard.
      let initialPromise = helper.checkTriageConfig(component17, event, helper);
      initialPromise.then($A.getCallback(function() {
        component17.set('v.initialized', true);
        helper.setWizardSteps(component17);
        helper.setLoading(component17, false);
        helper.changeSubtitle(component17);
        helper.hideBackButton(component17);
        helper.setProgressStep(component17, 'ffss');
      })).catch($A.getCallback(function() {
        helper.setLoading(component17, false);
        helper.showError(component17, $A.get('{!$Label.c.Lc_arce_NewARCE_UnexpectedError}'));
      }));
    } else if (resumeArce) {
      // Component invoked from RAIP (resume). Actions: Check config, get RAIP data, call persistence and run wizard.
      let initialPromise = helper.checkTriageConfig(component17, event, helper);
      initialPromise.then(function() {
        return helper.getRaipData(component17);
      }).then(function() {
        helper.setWizardSteps(component17);
        return helper.callPersistenceService(component17, helper);
      }).then(function() {
        helper.initStep(component17, helper);
      }).catch(function() {
        // Check if ARCE has been created. If so, there was an error in the persistence call.
        helper.catchError(component17, helper);
      });
    } else {
      // Component invoked from wizard (new). Actions: Check config, create RAIP, call persistence and run wizard.
      let initialPromise = helper.checkTriageConfig(component17, event, helper);
      initialPromise.then(function() {
        helper.setWizardSteps(component17);
        return helper.newRaip(component17);
      }).then(function() {
        return helper.callPersistenceService(component17, helper);
      }).then(function() {
        return helper.callRiskFilterService(component17, helper);
      }).then(function() {
        helper.initStep(component17, helper);
      }).catch(function() {
        helper.catchError(component17, helper);
      });
    }
  },
  catchError: function(component, helper) {
    helper.setLoading(component, false);
    const arceId = component.get('v.analysisId');
    if (arceId) {
      helper.showError(component, $A.get('{!$Label.c.Arc_Gen_RAIP_ErrorCreationOrPersistence}'));
    } else {
      helper.showError(component, $A.get('{!$Label.c.Lc_arce_NewARCE_UnexpectedError}'));
    }
  },

  initStep: function(component, helper) {
    component.set('v.initialized', true);
    helper.setLoading(component, false);
    helper.changeSubtitle(component);
    helper.hideBackButton(component);
    helper.enableNextButton(component, component.get('v.isRAIPSelectWorkflow'));
  },

  newRaip: function(component18) {
    const helper = this; // eslint-disable-line
    // Show spinner.
    this.setLoading(component18, true);

    // Call server action.
    var recordId = component18.get('v.recordId');
    var actualClient = component18.get('v.actualClient');
    let typeSelctd = component18.get('v.typeSelected');
    var newanalysis = component18.get('c.setanalysis');

    var params = {
      'recordId': recordId,
      'isorphan': 'false',
      'orphanNumber': '',
      'accounts': '[]',
      'analysisType': '4',
      'actualClient': actualClient.accNumber,
      'typeSelected': typeSelctd
    };
    newanalysis.setParams({
      data: params
    });

    return this.promisifyAndCallAction(newanalysis)
      .then(function(result) {
        var resp = JSON.parse(result);
        if (resp.status === 'NUEVO') {
          component18.set('v.existentAnalysis', false);
        } else if (resp.status === 'EXISTENTE') {
          component18.set('v.existentAnalysis', true);
        }
        component18.set('v.clientNumber', resp.clientnumber);
        component18.set('v.analysisId', resp.analysisId);
        component18.set('v.accHasAnalysisId', resp.accAnalyGpId);
      })
      .catch(function(errors) {
        helper.showError(component18, errors[0].message);
        $A.get('e.force:closeQuickAction').fire();
        throw new Error('Execution failed');
      });
  },

  getRaipData: function(component21) {
    // Get RAIP data for existing ARCE.
    var action = component21.get('c.getRAIPData');

    action.setParams({
      analysisId: component21.get('v.arceIdToResume')
    });

    return this.promisifyAndCallAction(action)
      .then(function(result) {
        const outputJson = JSON.parse(result);
        const serviceResponse = JSON.parse(outputJson.serviceMessage);
        component21.set('v.analysisId', serviceResponse.analysisId);
        component21.set('v.accHasAnalysisId', serviceResponse.accHasAnalysisId);
        component21.set('v.customerId', serviceResponse.customerId);
      });
  },

  checkTriageConfig: function(component, event, helper) {
    const getTriasConfg = this.getTriageConfig(component);
    const getRAIPSelectMetadata = this.getRAIPSelectMetadata(component);
    const getOptionsWf = this.getLabelCombo(component, event, helper);
    const getOptionsMdl = this.getMdlOptns(component);
    const buttonEEFF = component.get('v.changeFfssMode');
    return Promise.all([getTriasConfg, getRAIPSelectMetadata, getOptionsWf, getOptionsMdl])
      .then(function(responses) {
        const triageConfigRes = responses[0];
        const RAIPSelectMetadata = responses[1];
        const optionsWf = responses[2];
        const optionsModls = responses[3];

        component.set('v.ratingToolStepEnabled', !triageConfigRes.triageCallEnabled);
        component.set('v.ratingToolOptions', triageConfigRes.ratingToolList);
        component.set('v.isRAIPSelectWorkflow', RAIPSelectMetadata);
        component.set('v.options', optionsWf);
        component.set('v.optionsMdls', optionsModls);
        if (optionsModls.length && !buttonEEFF) {
          component.set('v.currentStep', 'selectModel');
          helper.setProgressStep(component, 'selectModel');
          helper.enableNextButton(component, true);
        } else if (RAIPSelectMetadata && !buttonEEFF) {
          component.set('v.currentStep', 'selectRAIPWf');
          helper.setProgressStep(component, 'selectRAIPWf');
          helper.enableNextButton(component, false);
          helper.isDisableNext(component, helper);
        } else if (component.get('v.ratingToolStepEnabled') && component.get('v.preStepTriage') && !buttonEEFF) {
          component.set('v.currentStep', 'preTool');
          helper.setProgressStep(component, 'preTool');
        } else {
          component.set('v.currentStep', 'ffss');
          helper.setProgressStep(component, 'ffss');
        }
      });
  },

  checkGlobalRunWayConfig: function(component) {
    if (!component.get('v.changeFfssMode')) {
      var actualClient = component.get('v.actualClient');
      var globalId = actualClient.globalId;
      var isNew = component.get('v.arceIdToResume') === '';
      component.set('v.globalCustomerId', globalId);
      var action = component.get('c.globalRunWayConfig');
      this.setLoading(component, true);
      return this.promisifyAndCallAction(action)
        .then(result => {
          var newStep =  isNew && result.gblRunWayEnabled ? 'globalRunWay' : 'ffss';
          component.set('v.globalRunWayStepEnabled', result.gblRunWayEnabled);
          component.set('v.blockLocalOption', result.blockLocalOption);
          component.set('v.currentStep', newStep);
        });
    } else {
      return new Promise($A.getCallback((resolve, reject) => {
        component.set('v.currentStep', 'ffss');
        resolve();
      }));
    }
  },

  getURLConfig: function(component) {
    var action = component.get('c.localURLs');
    this.setLoading(component, true);
    return this.promisifyAndCallAction(action)
      .then(result => {
        component.set('v.orgURL', result.orgURL);
        component.set('v.vfURL', result.vfURL);
      });
  },

  setWizardSteps: function(component) {
    // List of steps.
    const arceTypeStep = { label: $A.get('{!$Label.c.Arc_Gen_Analysis_ST_ArceType}'), value: 'arceTypeSelection' };
    const groupStructureStep = { label: $A.get('{!$Label.c.Arc_Gen_Analysis_ST_GroupStructure}'), value: 'groupStructure' };
    const globalRunWayStep = { label: $A.get('{!$Label.c.Arc_Gen_Analysis_ST_GlobalRunWay}'), value: 'globalRunWay' };
    const ffssStep = { label: $A.get('{!$Label.c.Arc_Gen_Analysis_ST_FFSS}'), value: 'ffss' };
    const ratingToolStep = { label: $A.get('{!$Label.c.Arc_Gen_Analysis_ST_RatingTool}'), value: 'tool' };
    const preRatingToolStep = { label: $A.get('{!$Label.c.Arc_Gen_Analysis_ST_PreRatingTool}'), value: 'preTool' };
    const irpWFV2 = { label: $A.get('{!$Label.c.Arc_Gen_Analysis_ST_SelectWf}'), value: 'selectRAIPWf' };
    const redirectToArceStep = { label: $A.get('{!$Label.c.Arc_Gen_Analysis_ST_RedirectToARCE}'), value: 'redirectToArce' };
    const modelStep = { label: 'Model Selection', value: 'selectModel' };
    const corpRenewal = { label: 'Renew ARCE', value: 'corpRenewal' };
    var stepMap = {
      'arceTypeStep': arceTypeStep,
      'groupStructureStep': groupStructureStep,
      'globalRunWayStep': globalRunWayStep,
      'ffssStep': ffssStep,
      'ratingToolStep': ratingToolStep,
      'preRatingToolStep': preRatingToolStep,
      'irpWFV2': irpWFV2,
      'redirectToArceStep': redirectToArceStep,
      'modelStep': modelStep,
      'corpRenewal': corpRenewal
    };

    //Determine actual step list, depending on whether rating tool needs to be selected.
    const ratingToolStepEnabled = component.get('v.ratingToolStepEnabled');
    const irpWFV2Enable = component.get('v.isRAIPSelectWorkflow');
    const irpWFV2Selected = component.get('v.RAIPSelectComboValue');
    const buttonEEFF = component.get('v.changeFfssMode');
    const globalRunWayStepEnabled = component.get('v.globalRunWayStepEnabled');
    var steps = [];

    if (irpWFV2Enable && !buttonEEFF) {
      if (irpWFV2Selected === $A.get('{!$Label.arce.Arc_Gen_NewRaipRatingApi}') && ratingToolStepEnabled) {
        steps = [arceTypeStep, globalRunWayStep, groupStructureStep, irpWFV2, ffssStep, ratingToolStep, redirectToArceStep];
      } else if (irpWFV2Selected === $A.get('{!$Label.arce.Arc_Gen_NewRaipRatingApi}')) {
        steps = [arceTypeStep, globalRunWayStep, groupStructureStep, irpWFV2, ffssStep, redirectToArceStep];
      } else {
        steps = [arceTypeStep, modelStep, irpWFV2, corpRenewal, ffssStep, redirectToArceStep];
      }
    } else if (ratingToolStepEnabled) {
      steps = this.ratingToolSteps(component, stepMap);
    } else {
      steps = [arceTypeStep, globalRunWayStep, groupStructureStep, ffssStep, redirectToArceStep];
    }

    if (!globalRunWayStepEnabled && !irpWFV2Enable) {
      steps.splice(1, 1);
    }
    /* Fire event. */
    const wzrdEvent = component.getEvent('wizardEvent');
    wzrdEvent.setParams({
      'eventType': 'setProgressSteps',
      parameters: { steps }
    });
    wzrdEvent.fire();
  },

  ratingToolSteps: function(component, stepMap) {
    var steps = [];
    if (component.get('v.preStepTriage') && !component.get('v.postStepTriage')) {
      steps = [stepMap.arceTypeStep, stepMap.globalRunWayStep, stepMap.groupStructureStep, stepMap.preRatingToolStep, stepMap.ffssStep, stepMap.redirectToArceStep];
    } else if (component.get('v.preStepTriage') && component.get('v.postStepTriage')) {
      steps = [stepMap.arceTypeStep, stepMap.globalRunWayStep, stepMap.groupStructureStep, stepMap.preRatingToolStep, stepMap.ffssStep, stepMap.ratingToolStep,
        stepMap.redirectToArceStep];
    } else {
      steps = [stepMap.arceTypeStep, stepMap.globalRunWayStep, stepMap.groupStructureStep, stepMap.ffssStep, stepMap.ratingToolStep, stepMap.redirectToArceStep];
    }
    return steps;
  },

  callPersistenceService: function(component, helper) {
    var action = component.get('c.callPersistence');
    var analysisId = component.get('v.analysisId');
    var customerId = component.get('v.customerId');
    action.setParams({
      analysisId, customerId
    });
    this.setLoading(component, true);

    return this.promisifyAndCallAction(action);
  },

  callTriageService: function(component) {
    var action = component.get('c.callTriage');
    var analysisId = component.get('v.analysisId');
    var customerId = component.get('v.customerId');
    action.setParams({
      analysisId, customerId
    });
    this.setLoading(component, true);

    return this.promisifyAndCallAction(action)
      .then(result => {
        const response = JSON.parse(result.serviceMessage);
        component.set('v.arceInScope', response.arceInScope);
        component.set('v.riskSegment', response.riskSegment);
      });
  },

  persistData: function(component22, event) {
    var helper = this;  // eslint-disable-line
    var action = component22.get('c.persistRatingModel');
    action.setParams({
      'accHasAnalysisId': component22.get('v.accHasAnalysisId'),
      'ratingModelValue': component22.get('v.ratingTool'),
      'raipType': component22.get('v.ratingType'),
      'triageConfig': component22.get('v.rtngToolType')
    });

    return this.promisifyAndCallAction(action)
      .then(function(result) {
        const res = JSON.parse(result);
        const toastEvent = $A.get('e.force:showToast');
        if (res.saveStatus === 'true') {
          component22.set('v.analysisId', res.analysisId);
          toastEvent.setParams({
            'title': $A.get('{!$Label.c.Lc_arce_newAnalysisSuccess}'),
            'type': 'success',
            'duration': '8000',
            'message': ''
          });
          toastEvent.fire();
        } else {
          helper.showError(component22, $A.get('{!$Label.c.Lc_arce_NewARCE_UnexpectedError}'));
          $A.get('e.force:closeQuickAction').fire();
          throw new Error($A.get('{!$Label.c.Lc_arce_NewARCE_UnexpectedError}'));
        }
      });
  },
  handleFfssNext: function(component, helper) {
    return new Promise($A.getCallback(function() {
      const ffssTable = component.find('ffss-table');
      helper.setLoading(component, true);
      if (component.get('v.ratingToolStepEnabled')) {
        return helper.ratingToolsIRP(component, helper, ffssTable);
      } else {
        return helper.handlePromiseFFSS(component, helper, ffssTable);
      }
    }));
  },
  handlePromiseFFSS: function(component, helper, ffssTable) {
    ffssTable.callTablesEngine().then(function() {
      return helper.callTriageService(component);
    }).then(function() {
      return helper.persistData(component);
    }).then(function() {
      helper.redirectToArce(component, component.get('v.analysisId'), component.get('v.arceInScope'), component.get('v.riskSegment'));
    });
  },
  ratingToolsIRP: function(component, helper, ffssTable) {
    ffssTable.callTablesEngine().then(function() {
      const irpwfv2 = component.get('v.isRAIPSelectWorkflow');
      if (irpwfv2) {
        helper.handleIrpWfV2(component, helper);
      } else {
        helper.handleStepsTriage(component, helper);
      }
    }).catch(function() {
      helper.unsubscribe(component);
      helper.setLoading(component, false);
    });
  },
  handleIrpWfV2: function(component, helper) {
    helper.setRatingTool(component);
    if (component.get('v.modlSlctd') === '2012P1' || component.get('v.modlSlctd') === '2012') {
      helper.handleToolNextEngine(component);
    } else {
      helper.handleToolNext(component);
    }
  },
  handleStepsTriage: function(component, helper) {
    if (component.get('v.preStepTriage') && !component.get('v.postStepTriage')) { // pre triage - escape tool screen and finish arce
      helper.handleToolNext(component);
    } else if (component.get('v.preStepTriage') && component.get('v.postStepTriage')) { // BOTH triage - continue tool screen
      component.set('v.isDisabled', true);
      helper.handlePostTriageStep(component);
      component.set('v.currentStep', 'tool');
      helper.setProgressStep(component, 'tool');
      helper.setLoading(component, false);
      helper.enableNextButton(component, false);
      helper.changeSubtitle(component);
    } else { // POST (Default option)
      component.set('v.currentStep', 'tool');
      helper.setProgressStep(component, 'tool');
      helper.setLoading(component, false);
      helper.enableNextButton(component, false);
      helper.changeSubtitle(component);
    }
  },
  handleToolNextEngine: function(component) {
    const helper = this; // eslint-disable-line
    this.setLoading(component, true);

    const persistance = this.persistData(component);
    persistance.then(function() {
      if (!component.get('v.isCallSales')) {
        component.set('v.isCallSales', true);
        helper.getSalesEngineConfig(component, helper);
      } else if (component.get('v.isSalesEngine')) {
        helper.redirectToArce(component, component.get('v.analysisId'), true, component.get('v.riskSegment'));
      } else {
        helper.cancelArce(component, helper);
      }
      helper.setLoading(component, false);
      helper.unsubscribe(component);
    }).catch(function() {
      helper.showError(component, $A.get('{!$Label.c.Lc_arce_NewARCE_UnexpectedError}'));
      helper.setLoading(component, false);
    });
  },
  handleToolNext: function(component) {
    const helper = this; // eslint-disable-line
    this.setLoading(component, true);

    const persistance = this.persistData(component);
    persistance.then(function() {
      helper.redirectToArce(component, component.get('v.analysisId'), true);
      helper.unsubscribe(component);
    }).catch(function() {
      helper.showError(component, $A.get('{!$Label.c.Lc_arce_NewARCE_UnexpectedError}'));
      helper.setLoading(component, false);
    });
  },
  handleWFV2Next: function(component, event, helper) {
    helper.setRatingTool(component);
    const wfSelected = component.get('v.RAIPSelectComboValue');
    let checkPromise = helper.corpRenew(component, helper);
    checkPromise.then(function(dataWrapper) {
      if (wfSelected === $A.get('{!$Label.arce.Arc_Gen_NewRaipRatingApi}')) {
        //Si es Seleccionado IRP
        if (dataWrapper.renew) {
          component.set('v.currentStep', 'corpRenewal');
          helper.setProgressStep(component, 'corpRenewal');
          helper.setLoading(component, false);
          helper.changeSubtitle(component);
        } else {
          helper.enableNextButton(component, false);
          component.set('v.currentStep', 'ffss');
          helper.setProgressStep(component, 'ffss');
          const updtIrpWf = helper.irpWfUpdt(component);
          updtIrpWf.then(function() {
            helper.changeSubtitle(component);
          }).catch(function() {
            helper.showError(component, $A.get('{!$Label.c.Lc_arce_NewARCE_UnexpectedError}'));
            helper.setLoading(component, false);
          });
        }
      } else {
        //Si es Seleccionado ARP o CRP
        const ffssWAhas = helper.newFFSSWAhas(component);
        ffssWAhas.then(function() {
          if (wfSelected === 'ARP' && dataWrapper.renew) {
            component.set('v.currentStep', 'corpRenewal');
            helper.setProgressStep(component, 'corpRenewal');
            helper.setLoading(component, false);
            helper.changeSubtitle(component);
          } else {
            helper.handleToolNext(component);
          }
        }).catch(function() {
          helper.showError(component, $A.get('{!$Label.c.Lc_arce_NewARCE_UnexpectedError}'));
          helper.setLoading(component, false);
        });
      }
    }).catch(function() {
      helper.showError(component, $A.get('{!$Label.c.Lc_arce_NewARCE_UnexpectedError}'));
    });
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
  irpWfUpdt: function(component) {
    var action = component.get('c.irpWfUpdt');

    action.setParams({
      'accHasAnalysisId': component.get('v.accHasAnalysisId'),
      'flowSelected': component.get('v.RAIPSelectComboValue')
    });
    return this.promisifyAndCallAction(action);
  },

  handleGlobalRunWayNext: function(component, event, helper) {
    helper.setLoading(component, true);
    if (component.get('v.redirectToExternalOrg') === '2') {
      helper.redirectToOrg(component, helper);
      component.set('v.blockYES', true);
      component.set('v.blockLocalOption', true);
      helper.showWarning(component, $A.get('{!$Label.c.Arc_Gen_RAIP_GBL_redirect_warning}'));
      helper.setLoading(component, false);
    } else {
      helper.onInit(component, event, helper);
    }
  },

  hideBackButton: function(component) {
    const wzrdEvent = component.getEvent('wizardEvent');
    wzrdEvent.setParams({
      eventType: 'hideBack',
      parameters: { hidden: true }
    });
    wzrdEvent.fire();
  },

  enableNextButton: function(component, enabled) {
    const wzrdEvent = component.getEvent('wizardEvent');
    wzrdEvent.setParams({
      eventType: 'nextEnable',
      parameters: { enabled }
    });
    wzrdEvent.fire();
  },

  setLoading: function(component, loading) {
    const wzrdEvent = component.getEvent('wizardEvent');
    wzrdEvent.setParams({
      eventType: 'setLoading',
      parameters: { loading }
    });
    wzrdEvent.fire();
  },

  redirectToArce: function(component, arceId, arceInScope, riskSegment) {
    const wzrdEvent = component.getEvent('wizardEvent');
    wzrdEvent.setParams({
      eventType: 'redirectToArce',
      parameters: { arceId, arceNotInScope: !arceInScope, riskSegment }
    });
    wzrdEvent.fire();
  },

  showPostpone: function(component, shown) {
    const wzrdEvent = component.getEvent('wizardEvent');
    wzrdEvent.setParams({
      eventType: 'showPostpone',
      parameters: { shown }
    });
    wzrdEvent.fire();
  },

  changeSubtitle: function(component) {
    const wzrdEvent = component.getEvent('wizardEvent');
    const currentStep = component.get('v.currentStep');
    var subtitleText = '';

    switch (currentStep) {
      case 'preTool':
        subtitleText = $A.get('{!$Label.c.Arc_Gen_Analysis_ST_PreRatingTool}');
        break;
      case 'ffss':
        subtitleText = $A.get('{!$Label.c.Arc_Gen_Analysis_ST_FFSS}');
        break;
      case 'tool':
        subtitleText = $A.get('{!$Label.c.Arc_Gen_Analysis_ST_RatingTool}');
        break;
      case 'selectRAIPWf':
        subtitleText = $A.get('{!$Label.c.Arc_Gen_Analysis_ST_SelectWf}');
        break;
      case 'globalRunWay':
        subtitleText = $A.get('{!$Label.c.Arc_Gen_Analysis_ST_GlobalRunWay}');
        break;
      case 'corpRenewal':
        subtitleText = 'New or Renew ARCE';
        break;
    }

    wzrdEvent.setParams({
      eventType: 'showSubtitle',
      parameters: { text: subtitleText }
    });
    wzrdEvent.fire();
  },
  getRAIPSelectMetadata: function(component) {
    const getRAIPWfMetadata = component.get('c.isRAIPWfMetadata');
    return this.promisifyAndCallAction(getRAIPWfMetadata);
  },
  getTriageConfig: function(component) {
    const getTriConfig = component.get('c.getTriageConfig');
    getTriConfig.setParams({
      accHasId: component.get('v.accHasAnalysisId'),
      interName: component.get('v.interfaceFlowTriage'),
      stepConfig: component.get('v.stepTriageConfig')
    });
    return this.promisifyAndCallAction(getTriConfig);
  },
  handlePostTriageStep: function(component) {
    var action = component.get('c.handleTriageConfigBoth');
    action.setParams({
      interName: component.get('v.interfaceFlowTriage'),
      accHasId: component.get('v.accHasAnalysisId')
    });
    return this.promisifyAndCallAction(action)
      .then(function(result) {
        component.set('v.ratingToolOptionsOver', result.ratingTypeList);
      });
  },
  getLabelCombo: function(component, event, helper) {
    helper.enableNextButton(component, false);
    let prom;
    let profSet = component.get('v.profilingSet');
    if (profSet !== false && profSet) {
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
  getMdlOptns: function(component) {
    const getOptions = component.get('c.model2012Active');
    getOptions.setParams({
      raipType: 'RAIPCorp'
    });
    return this.promisifyAndCallAction(getOptions);
  },
  setProgressStep: function(component, step) {
    const wzrdEvent = component.getEvent('wizardEvent');
    wzrdEvent.setParams({
      eventType: 'setCurrentProgressStep',
      parameters: { step }
    });
    wzrdEvent.fire();
  },

  showError: function(component, message) {
    const wzrdEvent = component.getEvent('wizardEvent');
    wzrdEvent.setParams({
      eventType: 'showError',
      parameters: { error: message }
    });
    wzrdEvent.fire();
  },
  showWarning: function(component, message) {
    const wzrdEvent = component.getEvent('wizardEvent');
    wzrdEvent.setParams({
      eventType: 'showWarning',
      parameters: { warning: message }
    });
    wzrdEvent.fire();
  },
  isDisableNext: function(component, helper) {
    if (component.get('v.isDisabled')) {
      helper.enableNextButton(component, false);
    }
  },
  redirectToOrg: function(component, helper) {
    var winGoogle = window.open(component.get('v.orgURL'), '_blank');
    setTimeout(function() {
      winGoogle.close();
      var form = document.getElementById('Formulario');
      form.submit();
    }, 5000);
  },

  promisifyAndCallAction: function(action1) {
    return new Promise($A.getCallback((resolve, reject) => {
      action1.setCallback(this, function(response) {
        const status = response.getState();
        if (status === 'SUCCESS') {
          const respValue1 = response.getReturnValue();

          if (respValue1 !== null && typeof respValue1 === 'object') {
            // Check whether response is a ServiceAndSaveResponse object.
            const serviceCode = respValue1.serviceCode;
            const saveStatus = respValue1.saveStatus;

            if (typeof serviceCode !== 'undefined' && !serviceCode.startsWith('2')) {
              reject(respValue1.serviceMessage);
            } else if (saveStatus === 'false') {
              reject(respValue1.saveMessage);
            } else {
              resolve(respValue1);
            }
          } else {
            resolve(respValue1);
          }
        } else {
          reject(response.getError());
        }
      });

      $A.enqueueAction(action1);
    }));
  },
  callRiskFilterService: function(component, helper) {
    var action = component.get('c.callRiskFilter');
    var customerId = component.get('v.customerId');
    var arceId = component.get('v.analysisId');
    action.setParams({
      customerId,
      arceId
    });
    this.setLoading(component, true);

    return this.promisifyAndCallAction(action);
  },
  callbackSuscribe: function(component24, event, helper) {
    // Get the empApi component
    const empApi = component24.find('empApi');
    const channel = component24.get('v.channel');
    const replayId = -1;
    const callback = function(message) {
      console.log('Event Received : ' + JSON.stringify(message));
      helper.onReceiveNotification(component24, message, helper);
    };

    // Subscribe to the channel and save the returned subscription object.
    empApi.subscribe(channel, replayId, callback).then(function(newSubscription) {
      console.log('Subscribed to channel ' + channel);
      component24.set('v.subscription', newSubscription);
    });
  },
  unsubscribe: function(component25) {
    const empApi = component25.find('empApi');
    if (empApi) {
      const subscription = component25.get('v.subscription');
      empApi.unsubscribe(subscription, $A.getCallback(unsubscribed => {
        component25.set('v.subscription', null);
      }));
    }
  },
  onReceiveNotification: function(component26, message, helper) {
    // Extract notification from platform event
    const newNotification = {
      time: $A.localizationService.formatDateTime(
        message.data.payload.CreatedDate, 'HH:mm'),
      message: message.data.payload.arce__Message__c
    };

    // Save notification in history
    const notifications = component26.get('v.notifications');
    notifications.push(newNotification);
    component26.set('v.notifications', notifications);
    component26.set('v.isDisabled', true);

    // Display notification in a toast
    helper.showError(component26, newNotification.message);
    $A.get('e.force:closeQuickAction').fire();
    helper.displayToast(component26, 'ERROR', newNotification.message);
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
  checkRatingTypeByModel: function(component, event, helper) {
    return new Promise($A.getCallback((resolve, reject) => {
      var action = component.get('c.checkRatingType');
      var analysis = component.get('v.accHasAnalysisId');
      var modelSel = component.get('v.modlSlctd');
      var changeFfssMode = component.get('v.changeFfssMode');
      action.setParams({
        analysisId: analysis,
        modelSelec: modelSel,
        eeffButton: changeFfssMode
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var responseWrapper = response.getReturnValue();
          component.set('v.ratingTypeOptions', responseWrapper);
          resolve(responseWrapper);
        } else {
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  getStepsTriage: function(component) {
    var action = component.get('c.getIRPTriageStepConfig');
    return this.promisifyAndCallAction(action)
      .then(result => {
        if (result !== null) {
          var res = JSON.parse(result);
          if (res[0] === 'PRE') {
            component.set('v.preStepTriage', true);
          } else if (res[0] === 'POST') {
            component.set('v.postStepTriage', true);
          } else if (res[0] === 'BOTH') {
            component.set('v.preStepTriage', true);
            component.set('v.postStepTriage', true);
          }
          component.set('v.stepTriageConfig', res[0]);
          component.set('v.interfaceFlowTriage', res[1]);
        }
      });
  },
  checkRatingToolId: function(component, event, helper) {
    return new Promise($A.getCallback((resolve, reject) => {
      var action = component.get('c.checkRatingToolId');
      var analysis = component.get('v.accHasAnalysisId');
      var ratingTool = component.get('v.ratingToolSlctd');
      var interName = component.get('v.interfaceFlowTriage');
      action.setParams({
        analysisId: analysis,
        ratingTool: ratingTool,
        interName: interName
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          console.log('Suppress Warning:javascript:S4144_3');
          var responseWrapper = response.getReturnValue();
          component.set('v.ratingTypeOptions', responseWrapper);
          resolve(responseWrapper);
        } else {
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  corpRenew: function(component, helper) {
    return new Promise($A.getCallback((resolve, reject) => {
      var action = component.get('c.getRenewable');
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
    const wfSelected = component.get('v.RAIPSelectComboValue');
    let isRenew = component.get('v.corpRenewal') === 'yes';
    if (isRenew) {
      helper.cloneRecords(component, helper);
    } else {
      if (wfSelected === 'IRP') {
        component.set('v.currentStep', 'ffss');
        helper.setProgressStep(component, 'ffss');
        helper.setLoading(component, false);
        const updtIrpWf = helper.irpWfUpdt(component);
        updtIrpWf.then(function() {
          helper.changeSubtitle(component);
        }).catch(function() {
          helper.showError(component, $A.get('{!$Label.c.Lc_arce_NewARCE_UnexpectedError}'));
          helper.setLoading(component, false);
        });
      } else {
        helper.handleToolNext(component);
      }
    }
  },
  cloneRecords: function(component, helper) {
    return new Promise($A.getCallback((resolve, reject) => {
      var action = component.get('c.doCloneRecords');
      let current = component.get('v.accHasAnalysisId');
      let datacorp = component.get('v.dataCorp');
      let ratingtool = component.get('v.ratingTool');
      action.setParams({
        ahacurrent: current,
        data: JSON.stringify(datacorp),
        rarRating: ratingtool
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        const wfSelected = component.get('v.RAIPSelectComboValue');
        if (state === 'SUCCESS') {
          if (wfSelected === 'IRP') {
            helper.doCloneEEFF(component, helper, current, JSON.stringify(datacorp), ratingtool);
          } else {
            helper.handleToolNext(component);
          }
          component.set('v.ratingType', datacorp.Type);
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
      }
    });
    $A.enqueueAction(action);
  },
  setRatingTool: function(component) {
    let modlCondt = component.get('v.modlSlctd') && component.get('v.irpTypeSlctd');
    let concatSlctdTool = modlCondt ? component.get('v.modlSlctd').concat(component.get('v.irpTypeSlctd')) : component.get('v.irpTypeSlctd');
    concatSlctdTool = concatSlctdTool === '2019IRP' ? concatSlctdTool.concat(component.get('v.actualClient').participantType) : concatSlctdTool;
    component.set('v.ratingTool', concatSlctdTool);
  },
  getSalesEngine: function(component, helper) {
    console.log(component.get('v.ffssSelectedEngine'));
    var action = component.get('c.getSalesEngine');
    action.setParams({
      ahaId: component.get('v.accHasAnalysisId'),
      raipType: component.get('v.ratingType')
    });

    action.setCallback(this, function(response) {
      var state = response.getState();

      component.set('v.loading', false);
      if (state === 'SUCCESS') {
        var result = response.getReturnValue();
        component.set('v.isSalesEngine', result.calculationResult);
        if (result.calculationResult) {
          helper.redirectToArce(component, component.get('v.analysisId'), true, component.get('v.riskSegment'));
        } else {
          component.set('v.msgTable', '');
          if (result.code.includes('20')) {
            component.set('v.engineError', $A.get('{!$Label.c.Arc_Gen_NoSalesEngine}'));
          } else {
            component.set('v.engineError', $A.get('{!$Label.c.Arc_Gen_ErrorEngine}'));
          }
          component.set('v.showErrorSales', true);

          //helper.enableNextButton(component, false);
        }
      } else if (state === 'ERROR') {
        component.set('v.isCallSales', false);
        component.set('v.isSalesEngine', false);
        component.set('v.showErrorSales', true);
        component.set('v.engineError', $A.get('{!$Label.c.Arc_Gen_ErrorEngine}'));
      }
    });
    $A.enqueueAction(action);
  },
  getSalesEngineConfig: function(component, helper) {
    component.set('v.loading', true);
    var action = component.get('c.isSalesEngineConfig');

    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var result = response.getReturnValue();

        if (result) {
          helper.getSalesEngine(component, helper);
        } else {
          helper.redirectToArce(component, component.get('v.analysisId'), true, component.get('v.riskSegment'));
        }
      }
    });
    $A.enqueueAction(action);

  },
  cancelArce: function(component, helper) {
    component.set('v.loading', true);
    var action = component.get('c.cancelARCE');
    action.setParams({
      ahaId: component.get('v.accHasAnalysisId')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        helper.redirectToArce(component, component.get('v.analysisId'), true, component.get('v.riskSegment'));
      }
    });
    $A.enqueueAction(action);

  }
});