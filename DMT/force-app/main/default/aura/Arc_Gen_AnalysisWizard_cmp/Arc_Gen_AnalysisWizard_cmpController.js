({
  doInit: function(component, event, helper) {
    // Set initial step.
    const existingArceId = component.get('v.existingArceId');
    const resume = existingArceId !== '';
    var currentStep;
    if (component.get('v.redirect')) {
      currentStep = 'empty';  // empty screen
    } else {
      if (resume) {
        currentStep = 'checklist';
        helper.retrieveArceExisting(component);
      } else {
        currentStep = 'subprocess';
      }
    }
    component.set('v.currentStep', currentStep);
    component.set('v.analysisId', existingArceId);
    component.set('v.existentAnalysis', resume);
    helper.changeSubtitle(component);

    // Get configuration.
    helper.setLoading(component, true);

    // Set indicator values.
    component.set('v.sectorOptions', [
      { 'label': $A.get('$Label.c.Lc_arce_sectorGeneric'), 'value': '1' },
      { 'label': $A.get('$Label.c.Lc_arce_sectorConstruction'), 'value': '2' },
      { 'label': $A.get('$Label.c.Lc_arce_sectorHotels'), 'value': '3' },
      { 'label': $A.get('$Label.c.Arc_Gen_Agro'), 'value': '4' },
      { 'label': $A.get('$Label.c.Lc_arce_sectorRetail'), 'value': '5' },
      { 'label': $A.get('$Label.c.Lc_arce_sectorAutoRetail'), 'value': '6' }
    ]);
    if (component.get('v.accountInfo.isorphan')) {
      component.set('v.indicatorOptions', [ {'label': $A.get('$Label.c.Arc_Gen_No'), 'value': '1'} ]);
    } else {
      component.set('v.indicatorOptions', [{'label': $A.get('$Label.c.Arc_Gen_Yes'), 'value': '2'}, {'label': $A.get('$Label.c.Arc_Gen_No'), 'value': '1'}]);
    }

    const action = component.get('c.getCallTriageEngineConfig');
    helper.promisifyAndCallAction(action)
      .then(function(result) {
        component.set('v.callTriageEngine', result);

        // Set list of steps.
        const wizardEvt = component.getEvent('wizardEvent');
        wizardEvt.setParams({
          'eventType': 'setProgressSteps',
          parameters: { 'steps': [
            { label: $A.get('{!$Label.c.Arc_Gen_Analysis_ST_ArceType}'), value: 'arceTypeSelection' },
            { label: $A.get('{!$Label.c.Arc_Gen_Analysis_ST_GroupStructure}'), value: 'groupStructure' },
            { label: $A.get('{!$Label.c.Arc_Gen_Analysis_ST_Subprocess}'), value: 'subprocess' },
            { label: $A.get('{!$Label.c.Arc_Gen_Analysis_ST_Checklist}'), value: 'checklist' },
            { label: $A.get('{!$Label.c.Arc_Gen_Analysis_ST_Sector}'), value: 'sector' },
            { label: $A.get('{!$Label.c.Arc_Gen_Analysis_ST_RedirectToARCE}'), value: 'redirectToArce' }
          ]}
        });
        wizardEvt.fire();

        helper.setProgressStep(component, currentStep);
        helper.setLoading(component, false);
      }).then(function() {
        helper.getPersistanceConfig(component, helper);
      }).catch(function(err) {
        helper.setLoading(component, false);
        helper.showError(component, $A.get('{!$Label.c.Lc_arce_NewARCE_UnexpectedError}'));
      });
  },

  closeModal: function(component, event, helper) {
    component.getEvent('closeModalRequestEvent').fire();
  },

  handleSubprocessChange: function(component, event, helper) {
    const selectedSubprocess = event.getSource().get('v.value');
    component.set('v.subprocess', selectedSubprocess);

    // Enable 'Next' button if selectedSubprocess != null.
    if (selectedSubprocess) {
      const wizardEvt = component.getEvent('wizardEvent');
      wizardEvt.setParams({
        eventType: 'nextEnable',
        parameters: { enabled: true }
      });
      wizardEvt.fire();
    }
  },

  handleRadioJustificationClick: function(component, event, helper) {
    const selectedJustification = event.getSource().get('v.value');
    component.set('v.justification', selectedJustification);

    // Enable 'Next' button if selectedJustification != null.
    if (selectedJustification) {
      const wizardEvt = component.getEvent('wizardEvent');
      wizardEvt.setParams({
        eventType: 'nextEnable',
        parameters: { enabled: true }
      });
      wizardEvt.fire();
    }
  },

  handleChangeWarningList: function(component, event, helper) {
    const checkboxes = component.find('warning-list-checkbox');
    const nextEnabled = checkboxes.every(function(checkbox) {
      return checkbox.get('v.checked');
    });
    helper.enableNextButton(component, nextEnabled);
  },

  handleChangeSectorList: function(component, event, helper) {
    const value = event.getSource().get('v.value');
    component.set('v.selectedSector', value);

    helper.checkEnableSectorNext(component);
  },

  handleChangeIndicator: function(component, event, helper) {
    const value = event.getSource().get('v.value');
    component.set('v.selectedIndicator', value);

    helper.checkEnableSectorNext(component);
  },

  handleNext: function(component, event, helper) {
    const currentStep = component.get('v.currentStep');
    switch (currentStep) {
      case 'subprocess':
        helper.handleSubprocessNext(component);
        break;
      case 'justification':
        helper.handleJustificationNext(component);
        break;
      case 'warningmessage':
        helper.handleWarningMessageNext(component);
        break;
      case 'checklist':
        helper.handleChecklistNext(component);
        break;
      case 'sector':
        helper.handleSectorNext(component, helper);
        break;
    }
  },

  handleBack: function(component, event, helper) {
    switch (component.get('v.currentStep')) {
      case 'subprocess': {
        const wizardEvt = component.getEvent('wizardEvent');
        wizardEvt.setParams({
          eventType: 'goBack'
        });
        wizardEvt.fire();
        return;
      }
      case 'justification':
        component.set('v.currentStep', 'subprocess');
        helper.setProgressStep(component, 'subprocess');
        helper.changeSubtitle(component);
        return;
      case 'warningmessage':
        component.set('v.currentStep', 'justification');
        helper.setProgressStep(component, 'justification');
        helper.enableNextButton(component, false);
        helper.changeSubtitle(component);
        return;
    }
  }
});