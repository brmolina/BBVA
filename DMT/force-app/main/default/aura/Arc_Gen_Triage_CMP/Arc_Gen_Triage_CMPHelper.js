({
  getAhaExtension: function(component, event, helper) {
    var action = component.get('c.getAhaExtensionId');
    action.setParams({
      ahaId: component.get('v.accHasAnalysisId')
    });
    action.setCallback(this, function(response) {
      var resp = response.getReturnValue();
      var state = response.getState();
      if (state === 'SUCCESS') {
        component.set('v.ahaExtensionId', resp);
        helper.enableNextButton(component, false);
      } else if (state === 'ERROR') {
        console.log('ERROR');
      }
    });
    $A.enqueueAction(action);
  },
  enableNextButton: function(component, enabled) {
    const wzrdEvent = component.getEvent('wizardEvent');
    wzrdEvent.setParams({
      eventType: 'nextEnable',
      parameters: { enabled }
    });
    wzrdEvent.fire();
  },
  nextStep: function(component, event, helper) {
    helper.saveForm(component, event, helper);
  },
  changeFieldGeneral: function(component, event, helper) {
    helper.saveForm(component, event, helper);
    var isgroupTreasury = component.find('arce__group_treasury_subsidiary__c').get('v.value');
    var isexplicit = component.find('arce__explicit_guarantee__c').get('v.value');
    var islegalEEFF = component.find('arce__legal_EEFF__c').get('v.value');
    var islevelShell = component.find('arce__level_Shell__c').get('v.value');

    component.set('v.islegalEEFF', islegalEEFF);
    component.set('v.isExplicit', isexplicit);
    component.set('v.isTreasury', isgroupTreasury);

    var enableNextButton = isgroupTreasury || isexplicit || islegalEEFF || islevelShell;
    helper.enableNextButton(component, enableNextButton);
    helper.checkFlow(component, event, helper);

  },
  handleChangeTreasury: function(component, event, helper) {
    var isgroupTreasury = component.find('arce__group_treasury_subsidiary__c').get('v.value');

    if (!isgroupTreasury) {
      component.set('v.isfilialCore', false);
      component.set('v.isGroupCorporate', false);
    }
  },
  handleChangeEEFF: function(component, event, helper) {
    var islegalEEFF = component.find('arce__legal_EEFF__c').get('v.value');

    if (!islegalEEFF) {
      component.set('v.isMatrizIg', false);
      component.set('v.isCountryEEUUCanada', false);
      component.set('v.isfilialCore', false);
      component.set('v.isGroupCorporate', false);
    }
  },
  handleChangeExplicit: function(component, event, helper) {
    var isexplicit = component.find('arce__explicit_guarantee__c').get('v.value');

    if (!isexplicit) {
      component.set('v.isfilialCore', false);
      component.set('v.isGroupCorporate', false);
    }
  },
  handleChangeCore: function(component, event, helper) {
    component.set('v.isfilialCore', !component.get('v.isfilialCore'));
  },
  handleChangeCorporate: function(component, event, helper) {
    component.set('v.isGroupCorporate', !component.get('v.isGroupCorporate'));
  },
  handleChangeEEUU: function(component, event, helper) {
    component.set('v.isCountryEEUUCanada', !component.get('v.isCountryEEUUCanada'));
  },
  handleChangeIg: function(component, event, helper) {
    component.set('v.isMatrizIg', !component.get('v.isMatrizIg'));
  },
  saveForm: function(component, event, helper) {
    event.preventDefault();
    var fields = event.getParam('fields');
    component.find('extensionForm').submit(fields);
  },
  getParticipantType: function(component, event, helper) {
    var action = component.get('c.getParticipantType');
    action.setParams({
      ahaId: component.get('v.accHasAnalysisId')
    });
    action.setCallback(this, function(response) {
      var resp = response.getReturnValue();
      var state = response.getState();
      if (state === 'SUCCESS') {
        component.set('v.participantType', resp);
      }
    });
    $A.enqueueAction(action);
  },
  returnJsonFlow: function(component, event, helper) {
    var action = component.get('c.returnJsonFlow');
    action.setCallback(this, function(response) {
      var resp = response.getReturnValue();
      var state = response.getState();
      if (state === 'SUCCESS') {
        component.set('v.jsonFlow', JSON.parse(resp));

        console.log(JSON.parse(resp));
      }
    });
    $A.enqueueAction(action);
  },
  checkFlow: function(component, event, helper) {
    var jsonFlow = component.get('v.jsonFlow');
    var flow = null;
    for (let index = 0; index < jsonFlow.length; index++) {
      var fieldsTrue = jsonFlow[index].fieldsTrue.split(',');
      var fieldsFalse = jsonFlow[index].fieldsFalse.split(',');

      var isThisFlowTrue = helper.checkFields(component, helper, fieldsTrue, true);
      var isThisFlowFalse = helper.checkFields(component, helper, fieldsFalse, false);

      if (isThisFlowTrue && isThisFlowFalse) {
        flow = jsonFlow[index].flow;
        break;
      }
    }

    if (flow === null) {
      component.set('v.errorMessage', $A.get('$Label.c.Arc_Gen_RTC_NoFlow'));
      component.set('v.isErrorMessage', true);
      helper.enableNextButton(component, false);
    } else {
      component.set('v.errorMessage',  []);
      component.set('v.isErrorMessage',  false);
    }
  },
  checkFields: function(component, helper, fields, isTrue) {
    var isThisFlow = true;
    for (let i = 0; i < fields.length; i++) {
      //Check if is an array beacuse core or group corporate its 3 times in component
      if (Array.isArray(component.find(fields[i]))) {
        if (component.find(fields[i])[0].get !== undefined) {
          var thisField1 = component.find(fields[i])[0].get('v.value');
          isThisFlow = helper.checkThisFields(thisField1, isTrue, isThisFlow);
        }
      } else {
        if (component.find(fields[i]).get !== undefined) {
          var thisField2 = component.find(fields[i]).get('v.value');
          isThisFlow = helper.checkThisFields(thisField2, isTrue, isThisFlow);
        }
      }
    }
    return isThisFlow;
  },
  checkThisFields: function(thisField, isTrue, isThisFlow) {
    if (thisField !== undefined) {
      if (isTrue) {
        isThisFlow = isThisFlow && thisField;
      } else {
        isThisFlow = isThisFlow && !thisField;
      }
    } else if (isTrue) {
      isThisFlow = false;
    }
    return isThisFlow;
  }
});