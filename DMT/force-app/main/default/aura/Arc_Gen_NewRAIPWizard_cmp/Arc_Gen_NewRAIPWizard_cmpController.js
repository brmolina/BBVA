({
  doInit: function(component, event, helper) {
    let initialPromise = helper.checkGlobalRunWayConfig(component);
    const alertEEFF = $A.get('$Label.c.Arce_Gen_MsgEEFFLessHundredMil');
    initialPromise.then(function() {
      return helper.getStepsTriage(component);
    }).then(function() {
      if (component.get('v.currentStep') === 'ffss') {
        var action = component.get('c.getShowEEFFCorpMessage');
        action.setCallback(this, function(a) {
          var state = a.getState();
          if (state === 'SUCCESS') {
            var value = a.getReturnValue();
            if (value === true) {
              component.set('v.warningEEFF', alertEEFF.split('<br>'));
            }
            helper.onInit(component, event, helper);
          }
        });
        $A.enqueueAction(action);
      } else {
        helper.setProgressStep(component, 'globalRunWay');
        helper.getURLConfig(component);
        component.set('v.initialized', true);
        helper.hideBackButton(component);
        helper.setLoading(component, false);
        helper.enableNextButton(component, false);
        helper.changeSubtitle(component);
        helper.hideBackButton(component);
        const irpwfv2 = component.get('v.isRAIPSelectWorkflow');
        if (irpwfv2) {
          helper.setProgressStep(component, 'selectRAIPWf');
        } else {
          helper.setProgressStep(component, 'ffss');
        }
      }
    }).catch(function() {
      helper.handleCatchError(component);
    });
  },

  handleFfssSelection: function(component15, event, helper) {
    let initialPromise;
    if (component15.get('v.interfaceFlowTriage') && component15.get('v.preStepTriage')) {
      initialPromise = helper.checkRatingToolId(component15, event, helper);
    } else {
      initialPromise = helper.checkRatingTypeByModel(component15, event, helper);
    }
    initialPromise.then(function(responseWrapper) {
      const isValid = event.getParam('isValidFfss');
      const wasValid = component15.get('v.ffssValid');
      component15.set('v.ffssValid', isValid);
      component15.set('v.ffssSelected', true);
      const resPreRating = responseWrapper.find(element => element.value === 'Prerating');

      // Set 'pre-rating' if FFSS is not valid.
      if (!wasValid && isValid) {
        component15.set('v.ratingType', '');
        helper.enableNextButton(component15, false);
      } else if (!isValid && resPreRating !== undefined) {
        component15.set('v.ratingType', 'prerating');
        helper.enableNextButton(component15, true);
      } else {
        helper.enableNextButton(component15, false);
      }
    }).catch(function() {
      helper.showError(component15, $A.get('There is a problem with FFSS selection'));
    });
  },

  handleRatingTypeChange: function(component, event, helper) {
    helper.enableNextButton(component, true);
  },

  handleRatingToolChange: function(component, event, helper) {
    const selectedTool = event.getParam('value');
    component.set('v.rtngToolSlctd', selectedTool);
    let concatSlctdTool = component.get('v.modlSlctd') ? component.get('v.modlSlctd').concat(component.get('v.irpTypeSlctd'), component.get('v.rtngToolSlctd')) : selectedTool;
    concatSlctdTool = concatSlctdTool === '2019IRP' ? concatSlctdTool.concat(component.get('v.actualClient').participantType) : concatSlctdTool;
    component.set('v.ratingTool', concatSlctdTool);

    if (component.get('v.ratingToolStepEnabled') && component.get('v.stepTriageConfig') !== null) {
      const ratingTools = component.get('v.ratingToolOptions');
      ratingTools.forEach(function(element) {
        if (element.value === selectedTool) {
          component.set('v.ratingTool', selectedTool);
          component.set('v.rtngToolType', element.type);
        }
      });
    }
    helper.enableNextButton(component, selectedTool != null); // eslint-disable-line
  },

  handleOverRatingToolChange: function(component, event, helper) {
    const selectedType = event.getParam('value');
    component.set('v.overRtngToolSlctd', selectedType);
    component.set('v.ratingTool', selectedType);
    const ratingTools = component.get('v.ratingToolOptionsOver');
    ratingTools.forEach(function(element) {
      if (element.value === selectedType) {
        component.set('v.rtngToolType', element.type);
      }
    });
    helper.enableNextButton(component, selectedType != null); // eslint-disable-line
  },

  handleNext: function(component, event, helper) {
    const currentStep = component.get('v.currentStep');
    switch (currentStep) {
      case 'globalRunWay':
        helper.handleGlobalRunWayNext(component, event, helper);
        break;
      case 'preTool':
        helper.setProgressStep(component, 'ffss');
        component.set('v.currentStep', 'ffss');
        helper.initStep(component, helper);
        break;
      case 'ffss':
        helper.handleFfssNext(component, helper);
        break;
      case 'tool':
        helper.handleToolNext(component);
        break;
      case 'selectRAIPWf':
        helper.handleWFV2Next(component, event, helper);
        break;
      case 'selectModel':
        component.set('v.currentStep', 'selectRAIPWf');
        helper.enableNextButton(component, false);
        helper.changeSubtitle(component);
        helper.setProgressStep(component, 'selectRAIPWf');
        helper.isDisableNext(component, helper);
        break;
      case 'corpRenewal':
        helper.handleCorpRenwNext(component, event, helper);
        break;
    }
  },
  handleChange: function(component16, event, helper) {
    let selectedIrp = component16.get('v.RAIPSelectComboValue');
    component16.set('v.irpTypeSlctd', selectedIrp);
    let rarRatingTool = component16.get('v.IRPRarRatingTool');
    if (selectedIrp === $A.get('{!$Label.arce.Arc_Gen_NewRaipOverrideApi}') && rarRatingTool) {
      helper.enableNextButton(component16, true);
    } else if (selectedIrp === $A.get('{!$Label.arce.Arc_Gen_NewRaipAdjustmentApi}') || selectedIrp === $A.get('{!$Label.arce.Arc_Gen_NewRaipRatingApi}')) {
      helper.enableNextButton(component16, true);
    } else if (selectedIrp === $A.get('{!$Label.arce.Arc_Gen_NewRaipOverrideApi}')) {
      helper.enableNextButton(component16, false);
    }
  },
  handleRedirectChange: function(component, event, helper) {
    var target = event.getSource();
    component.set('v.redirectToExternalOrg', target.get('v.value'));
    helper.enableNextButton(component, true);
  },
  selectModl: function(component, event, helper) {
    const getOptionsWf = helper.getLabelCombo(component, event, helper);
    getOptionsWf.then(function(optns) {
      component.set('v.options', optns);
      helper.enableNextButton(component, true);
    }).catch($A.getCallback(function() {
      helper.setLoading(component, false);
      helper.showError(component, $A.get('{!$Label.c.Lc_arce_NewARCE_UnexpectedError}'));
    }));
  }
});