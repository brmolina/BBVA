({
  init: function(component, event, helper) {
    helper.initializeComponent(component, event, helper);
  },
  cancelAction: function(component, event, helper) {
    helper.cancelAction(component);
  },
  onSelectCustomer: function(component, event, helper) {
    var valueCombo = event.getParam('value');
    var mapCustomers = component.get('v.mapCustomers');
    var accHasAnalysis = mapCustomers[0][valueCombo];
    var newCustomerObject = {
      Name: accHasAnalysis.customerName,
      Rating: accHasAnalysis.ffssRatingFinal
    };
    component.set('v.customerSelected', valueCombo);
    component.set('v.customerDetailInfo', newCustomerObject);
    component.set('v.disableButtons', false);
  },
  finish: function(component, event, helper) {
    component.set('v.spinnerStatus', true);
    component.set('v.disableButtons', true);
    var ambit = component.get('v.ambit');
    helper.persistArceAction(component, event, helper)
      .then($A.getCallback(function() {
        helper.setAmbit(component, event, helper, ambit);
      }))
      .catch($A.getCallback(function(err) {
        helper.executeError(component, event, helper, err);
      }));
  },
  moveNext: function(component, event, helper) {
    component.set('v.spinnerStatus', true);
    var getCurrentStep = component.get('v.currentStep');
    if (getCurrentStep === '1') {
      var mapCustomers = component.get('v.mapCustomers');
      var accHasAnalysis = mapCustomers[0][component.get('v.customerSelected')];
      accHasAnalysis.mainSubsidiary = true;
      helper.updateMainSubsidiary(accHasAnalysis, component);
      component.set('v.currentStep', '2');
      component.set('v.title', $A.get('$Label.c.ARC_GEN_PROPOSE_SELECT_GROUP_STAGE'));
      helper.getStageValues(component, event, helper);
    } else if (getCurrentStep === '2') {
      helper.updateStageSetValues(component, event, helper);
      component.set('v.spinnerStatus', true);
      let promiseInitDeleg = helper.initDelegation(component, event, helper);
      promiseInitDeleg.then(function() {
        helper.evaluateDelegation(component, event, helper);
        component.set('v.spinnerStatus', false);
      });
    }
    component.set('v.disableButtons', true);
  },
  moveBack: function(component, event, helper) {
    var getCurrentStep = component.get('v.currentStep');
    if (parseInt(getCurrentStep, 10) > 1) {
      component.set('v.currentStep', (parseInt(getCurrentStep) - 1).toString());
    }
    component.set('v.disableButtons', false);
  },
  setAmbitValue: function(component, event, helper) {
    component.set('v.ambit', event.getParam('value'));
    component.set('v.disableButtons', false);
  },
  setStageValue: function(component, event, helper) {
    component.set('v.stagevalue', event.getParam('value'));
    component.set('v.disableButtons', false);
  },
});