({
  /**
   * Handles the component initialization.
   */
  doInit: function(component, event, helper) {
    component.set('v.loading', true);
    component.set('v.accountInfo.accounts', '[]');
    component.set('v.idofarceexecutor', component.get('v.recordId'));
    const resumeArce = component.get('v.continue');

    helper.checkArceExist(component, event, helper)
      .then(function(result) {
        if (result === '' || resumeArce) {
          // Set default steps
          component.set('v.currentStep', 'ratingSystemSelection');
          component.set('v.currentProgressStep', 'ratingSystemSelection');
          helper.initComponent(component, event, helper);
        } else {
          helper.redirectAnalysis(component, result);
        }
      })
      .catch(function() {
        component.set('v.nextDisabled', true);
      });
  },

  /**
   * Handles all the wizard events.
   */
  /* eslint-disable complexity */
  handleEventWizard: function(component, event, helper) {
    const eventType = event.getParam('eventType');
    const parameters = event.getParam('parameters');

    switch (eventType) {
      case 'nextEnable':
        component.set('v.nextDisabled', !parameters.enabled);
        break;
      case 'hideBack':
        component.set('v.backHidden', parameters.hidden);
        break;
      case 'setLoading':
        helper.evalSetLoading(component, parameters);
        break;
      case 'redirectToArce':
        helper.handleRedirect(component, 'analysis', parameters.arceId, parameters.arceNotInScope, parameters.riskSegment);
        break;
      case 'showSubtitle':
        component.set('v.subtitleText', parameters.text);
        break;
      case 'showWarning':
        component.set('v.warningMessage', parameters.warning);
        break;
      case 'showError':
        component.set('v.errorMessage', parameters.error);
        component.set('v.nextDisabled', true);
        break;
      case 'setProgressSteps':
        component.set('v.progressSteps', parameters.steps);
        break;
      case 'setCurrentProgressStep':
        component.set('v.currentProgressStep', parameters.step);
        break;
      case 'renovationMessage':
        helper.showRenovationMessage(component, parameters.arceId);
        break;
      case 'changeStep':
        helper.handleEventChangeStep(component, parameters);
        break;
      case 'ratingSystemChanged':
        helper.handleEventRatingSystem(component, parameters, helper);
        break;
    }
  },

  closeAccessModal: function(component, event, helper) {
    component.set("v.showAccessModal", false);

    const closeQA = $A.get("e.force:closeQuickAction");
    if (closeQA) {
        closeQA.fire();
    }
  },
  /* eslint-enable complexity */

  /**
   * Moves to the next step in the process.
   */
  moveNext: function(component, event, helper) {
    component.set('v.errorMessage', '');
    const currentStep = component.get('v.currentStep');

    switch (currentStep) {
      case 'ratingSystemSelection':
        helper.handleRatingSystemNext(component, event, helper);
        break;
      case 'sp2Analysis': {
        // Propagate next event into corporates wizard component.
        const rtc2021Wizard = component.get('v.RTC2021Analysis')[0];
        if (rtc2021Wizard && rtc2021Wizard.isValid()) {
          rtc2021Wizard.onNext();
        }
        break;
      }
      case 'ifisAnalysis': {
        // Propagate next event into ifis wizard component.
        const ifisWizard = component.get('v.ifisAnalysis')[0];
        if (ifisWizard && ifisWizard.isValid()) {
          ifisWizard.onNext();
        }
        break;
      }
    }
  },
  closeModalCustom: function(component, event, helper) {
    const closeModalEvent = component.getEvent('closeModalEvent');
    closeModalEvent.fire();
  }
});