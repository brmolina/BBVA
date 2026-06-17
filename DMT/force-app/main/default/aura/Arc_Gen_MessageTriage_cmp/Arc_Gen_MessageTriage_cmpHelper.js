({
  triageSubscribe: function(component, event, helper) {
    // Get the empApi component
    const empApi = component.find('empApi');
    const channel = component.get('v.channel');
    const replayId = -1;
    empApi.subscribe(channel, replayId, $A.getCallback(eventReceived => {
      // Process event (this is called each time we receive an event)
      console.log('Received event ', JSON.stringify(eventReceived));
      if (component.get('v.recordId') === eventReceived.data.payload.AnalysisId__c) {
        console.log(eventReceived.data.payload.Status__c);
        if (eventReceived.data.payload.Status__c === 'NotArce' || eventReceived.data.payload.Status__c === 'errAsync') {
          helper.createCmpSuscribe(component, helper, eventReceived);
        }
        helper.unsubscribe(component, event, helper);
      }
    }))
      .then(subscription => {
        console.log('Subscribed to channel ', subscription.channel);
        component.set('v.subscription', subscription);
      });
  },
  unsubscribe: function(component, event, helper) {
    // Get the empApi component
    const empApi = component.find('empApi');
    const subscription = component.get('v.subscription');
    empApi.unsubscribe(subscription, $A.getCallback(unsubscribed => {
      // Confirm that we have unsubscribed from the event channel
      console.log('Unsubscribed from channel ' + unsubscribed.subscription);
      component.set('v.subscription', null);
    }));
  },
  createCmpSuscribe: function(component, helper, eventReceived) {
    if (eventReceived.data.payload.Status__c === 'NotArce' || eventReceived.data.payload.Status__c === 'errAsync') {
      //create message
      var sev = 'error';// info, warning, error
      var tit = eventReceived.data.payload.Status__c === 'NotArce' ? $A.get('{!$Label.c.Arc_Gen_ErrTriage}') : $A.get('{!$Label.c.Arc_Gen_AsyncErrTriage}');
      $A.createComponent(
        'ui:message',
        { 'aura:id': 'messId', 'severity': sev, 'closable': 'false', 'title': tit },
        function(newMess, status, errorMessage) {
          if (status === 'SUCCESS') {
            var body = component.get('v.body');
            if (!body) {
              body = [];
            }
            body.push(newMess);
            component.set('v.body', body);
            helper.refresh(component);
          } else if (status === 'INCOMPLETE') {
            console.log('No response from server or client is offline.');
          } else if (status === 'ERROR') {
            console.log('Error: ' + errorMessage);
          }
        }
      );
    }
  },
  getArceData: function(component, event, helper) {
    var action = component.get('c.getAnalysisData');
    action.setParams({
      'arceId': component.get('v.recordId')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      var resp = response.getReturnValue();
      if (state === 'SUCCESS') {
        helper.handleArceData(component, event, helper, resp);
      }
    });
    $A.enqueueAction(action);
  },
  handleArceData: function(component, event, helper, resp) {
    var triageStatus = resp[0].arce__triageStatus__c;
    if (resp[0].arce__Stage__c  !== '3' && typeof triageStatus === 'undefined') {
      helper.triageSubscribe(component, event, helper);
    } else if (resp[0].arce__triageStatus__c  === '4' || resp[0].arce__triageStatus__c  === '3') {
      helper.createComponentUi(component, triageStatus);
    }
  },
  createComponentUi: function(component, triageStatus) {
    var sev = 'error';
    var tit = triageStatus === '4' ? $A.get('{!$Label.c.Arc_Gen_ErrTriage}') : $A.get('{!$Label.c.Arc_Gen_AsyncErrTriage}');
    $A.createComponent('ui:message', {'aura:id': 'messId', 'severity': sev, 'closable': 'false', 'title': tit}, function(newMess, status, errorMessage) {
      if (status === 'SUCCESS') {
        var body = component.get('v.body');
        if (!body) {
          body = [];
        }
        body.push(newMess);
        component.set('v.body', body);
      }
    });
  },
  refresh: function(component) {
    $A.get('e.force:refreshView').fire();
  }
});