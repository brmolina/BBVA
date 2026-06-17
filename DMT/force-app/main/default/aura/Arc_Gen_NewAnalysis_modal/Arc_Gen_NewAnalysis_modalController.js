({
  doInit: function(component, event, helper) {

    helper.getEEFFServiceCheck(component);
    component.set('v.loading', true);
    component.set('v.accountInfo.accounts', '[]');

    // Default to current account. If ARCE is analysis, this value will change.
    component.set('v.idofarceexecutor', component.get('v.recordId'));

    const profilingPromise = helper.profilingRating(component, event, helper);
    profilingPromise.then(function(resp) {
      component.set('v.profilingRating', resp);
      helper.newOrResume(component, event, helper);
    }).catch(function(err) {
      component.set('v.loading', false);
      if (typeof(err) === 'string') {
        component.set('v.errorMessage', $A.get('$Label.c.Lc_arce_NewARCE_CouldNotCreate').replace('{0}', err));
      } else {
        component.set('v.errorMessage', $A.get('$Label.c.Lc_arce_NewARCE_UnexpectedError'));
      }
      helper.changeSubtitle(component);
    });

  },

  changeArceSelection: function(component, event, helper) {
    component.set('v.selectedArceType', event.getParam('parameters').arceType);
    helper.setProfilingMsg(component, event, helper, event.getParam('parameters').arceType);
  },

  moveNext: function(component, event, helper) {
    component.set('v.errorMessage', '');
    switch (component.get('v.currentStep')) {
      case 'arceTypeSelection':
        helper.handleArceTypeNext(component);
        return;
      case 'groupStructure':
        helper.handleGroupStructureNext(component);
        return;
      case 'analysis': {
        // Propagate next event into wizard component.
        component.set('v.nextDisabled', true);
        const analysisWizard = component.find('analysis-wizard');
        analysisWizard.onNext();
        return;
      }
      case 'raip': {
        // Propagate next event into wizard component.
        const raipWizard = component.find('raip-wizard');
        raipWizard.onNext();
        return;
      }
      case 'sp2Analysis': {
        // Propagate next event into wizard component.
        const raipWizard = component.find('raip-corp');
        raipWizard.onNext();
        return;
      }
    }
  },

  moveBack: function(component, event, helper) {
    component.set('v.errorMessage', '');
    switch (component.get('v.currentStep')) {
      case 'groupStructure':
        component.set('v.currentStep', 'arceTypeSelection');
        component.set('v.currentProgressStep', 'arceTypeSelection');
        component.set('v.backHidden', true);
        helper.changeSubtitle(component);
        return;
      case 'analysis': {
        // Propagate back event into wizard component.
        const analysisWizard = component.find('analysis-wizard');
        analysisWizard.onBack();
        return;
      }
      case 'raip': {
        // Propagate next event into wizard component.
        const raipWizard = component.find('raip-wizard');
        raipWizard.onNext();
        return;
      }
    }
  },

  closeModal: function(component, event, helper) {
    const showCloseButton = component.get('v.showCloseButton');
    if (showCloseButton) {
      // Custom close behaviour.
      const closeModalEvent = component.getEvent('closeModalEvent');
      closeModalEvent.fire();
    } else {
      // Standard quick action close.
      $A.get('e.force:closeQuickAction').fire();
    }
  },

  redirectEvent: function(component, event, helper) {
    helper.showToast($A.get('{!$Label.c.Lc_arce_redirectingURL}'), 'error', $A.get('{!$Label.c.Lc_arce_wizardRedirectRevokeArce}'));
    $A.enqueueAction(component.get('c.closeModal'));
  },

  closeModalCustom: function(component, event, helper) {
    const closeModalEvent = component.getEvent('closeModalEvent');
    closeModalEvent.fire();
  },
  /* eslint-disable */
  handleWizardEvent: function(component, event, helper) {
    const eventType = event.getParam('eventType');
    const parameters = event.getParam('parameters');

    switch (eventType) {
      case 'nextEnable':
        component.set('v.nextDisabled', !parameters.enabled);
        break;
      case 'goBack':
        helper.handleWizardBack(component);
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
        component.set('v.nextDisabled', true);
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
    }
  }
  /* eslint-enable */
});