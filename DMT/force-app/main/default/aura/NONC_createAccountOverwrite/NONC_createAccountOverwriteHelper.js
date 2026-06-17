({//eslint-disable-line
  startCreate: function(component, event, helper) {
    
    let recordTypeId = component.get('v.pageReference').state.recordTypeId;
    if (recordTypeId !== undefined) {
      let initialAction = component.get('c.getGroupNonClientRTID');
      initialAction.setCallback(this, function(response) {
        if (response.getState() === 'SUCCESS' && helper.convertTo18(recordTypeId) === response.getReturnValue()) {
          component.set('v.isAddTY', true);
        }
        helper.detectRecordType(component, helper, helper.convertTo18(recordTypeId));
      });
      $A.enqueueAction(initialAction);
    } else {
      helper.detectRecordType(component, helper, helper.convertTo18(recordTypeId));
    }
  },
  detectRecordType: function(component, helper, recordTypeId) {

    if (recordTypeId === undefined) {
      let action = component.get('c.getDefaultRTId');
      action.setCallback(this, function(response) {
        if (response.getState() === 'SUCCESS') {
          component.set('v.defaultRTId', response.getReturnValue());
          helper.getDefaultRTName(component, helper, recordTypeId);
        }
      });
      $A.enqueueAction(action);
    } else {
      let action = component.get('c.getRTDeveloperName');
      action.setParams({
        'recordTypeId': recordTypeId
      });
      action.setCallback(this, function(response) {
        if (response.getState() === 'SUCCESS') {
          component.set('v.rtName', response.getReturnValue());
          helper.decisionCreate(component, helper, recordTypeId);
        }
      });
      $A.enqueueAction(action);
    }
  },
  getDefaultRTName: function(component, helper, recordTypeId) {

    let defaultRTid = component.get('v.defaultRTId');
    let splitValue = defaultRTid.split('||');
    let recordDefault;
    if (splitValue[0] === splitValue[1]) {
      helper.decisionCreate(component, helper, recordTypeId);
    } else {
      recordDefault = splitValue[0];

      let action = component.get('c.getRTDeveloperName');
      action.setParams({
        'recordTypeId': recordDefault
      });
      action.setCallback(this, function(response) {
        if (response.getState() === 'SUCCESS') {
          component.set('v.rtName', response.getReturnValue());
          helper.isAdditionalRT(component, helper, recordTypeId, recordDefault);
        }
      });
      $A.enqueueAction(action);
    }

  },
  isAdditionalRT: function(component, helper, recordTypeId, recordDefault) {

    let initialAction = component.get('c.getGroupNonClientRTID');
    initialAction.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS' && recordDefault === response.getReturnValue()) {
        component.set('v.isAddTY', true);
      }
      helper.decisionCreate(component, helper, recordTypeId);
    });
    $A.enqueueAction(initialAction);
  },
  decisionCreate: function(component, helper, recordTypeId) {

    if (recordTypeId === undefined) {
      let defaultRTid = component.get('v.defaultRTId');
      let splitValue = defaultRTid.split('||');
      let recordDefault;
      if (splitValue[0] === splitValue[1]) {
        recordDefault = null;
      } else {
        recordDefault = splitValue[0];
      }
      let action = component.get('c.getNonClientRTID');
      if (component.get('v.isAddTY')) {
        action = component.get('c.getGroupNonClientRTID');
      }

      action.setCallback(this, function(response) {
        if (response.getState() === 'SUCCESS') {
          if (recordDefault === response.getReturnValue()) {
            helper.createCmp(component);
          } else {
            var createRecordEvent = $A.get('e.force:createRecord');
            createRecordEvent.setParams({
              'entityApiName': 'Account',
              'recordTypeId': recordDefault
            });
            createRecordEvent.fire();
          }
        }
      });
      $A.enqueueAction(action);


    } else {
      helper.openNonlient(component, helper, recordTypeId);
    }
  },
  openNonlient: function(component, helper, recordTypeId) {

    let action = component.get('c.getNonClientRTName');
    if (component.get('v.isAddTY')) {
      action = component.get('c.getGroupNonClientRTName');
    }

    action.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        if (component.get('v.rtName').split('||')[0] === response.getReturnValue()) {
          helper.createCmp(component);
        } else if (component.get('v.rtName').split('||')[0] === 'New_Client_Onboarding'){
            helper.createCmpOnboarding(component);
        } else {
          var createRecordEvent = $A.get('e.force:createRecord');
          createRecordEvent.setParams({
            'entityApiName': 'Account',
            'recordTypeId': recordTypeId
          });
          createRecordEvent.fire();
        }
      }
    });
    $A.enqueueAction(action);
  },
  createCmp: function(component) {
    let staticLabelNew = $A.get('$Label.c.NClient_headerText_New');
    // Always go through the duplicate-detection screen (NONC_createNonClient).
    // That component is the one that later instantiates the final create form (LWC).
    $A.createComponent('c:NONC_createNonClient', {
      'headerText': staticLabelNew + ' ' + component.get('v.rtName').split('||')[1],
      'isOnAccount': true,
      'isAdditionalRT': component.get('v.isAddTY')
    },
    function(modalComponent, status, errorMessage) {
      if (status === 'SUCCESS') {
        //Appending the newly created component in div
        var body = component.find('showChildModal').get('v.body');
        body.push(modalComponent);
        component.find('showChildModal').set('v.body', body);
      } else if (status === 'INCOMPLETE') {
        console.log('Server issue or client is offline.');
      } else if (status === 'ERROR') {
        console.log('error');
      }
    }
    );
  },
  createCmpOnboarding: function(component) {
    var componentName = 'onb_createNonClientLWC';

    $A.createComponent(
      'c:ONB_createNonClientOnboardingWrapper',
      {
        componentName: componentName,
        accRecordTypeId: component.get('v.pageReference').state.recordTypeId
      },
      function(wrapperCmp, status, errorMessage) {
        if (status === 'SUCCESS') {
          var body = component.find('showChildModal').get('v.body');
          body.push(wrapperCmp);
          component.find('showChildModal').set('v.body', body);
        } else if (status === 'INCOMPLETE') {
          console.log('Server issue or client is offline.');
        } else if (status === 'ERROR') {
          console.error('Error creating ONB_createNonClientOnboardingWrapper:', errorMessage);
        }
      }
    );
  },
  handleComponentEvent: function(component, event, helper) {
    const message = event.getParam('message');
    if (message === 'Close component' || message === 'Cancel component' || message === 'Back component') {
      const navigateHome = $A.get('e.force:navigateToURL');
      navigateHome.setParams({ url: '/lightning/o/Account/home' });
      navigateHome.fire();
      component.destroy();
    }
  },
  convertTo18: function(input) {
    var output;
    if (input === undefined || input === 'undefined' || input === null) {
      console.log('One recordtype.');
    } else if (input.length === 15) {
      var addon = '';
      for (var block = 0; block < 3; block++) {
        var loop = 0;
        for (var position = 0; position < 5; position++) {
          var current = input.charAt(block * 5 + position);
          if (current >= 'A' && current <= 'Z') {
            loop += 1 << position;//eslint-disable-line
          }
        }
        addon += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ012345'.charAt(loop);
      }
      output = (input + addon);
    } else {
      return input;
    }
    return output;
  }
});