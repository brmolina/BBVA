({//eslint-disable-line
  fetchDiscardReasons: function(component, fieldName) {
    var action = component.get('c.getselectOptions');
    action.setParams({
      'objObject': component.get('v.objAlert'),
      'fld': fieldName
    });
    var opts = [];
    action.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        var allValues = Object.values(response.getReturnValue());
        var allLabel = Object.keys(response.getReturnValue());
        for (var i = 0; i < allValues.length; i++) {
          opts.push({
            class: 'optionClass',
            label: allLabel[i],
            value: allValues[i]
          });
        }
        if (opts.length > 0) {
          component.set('v.optionsDiscard', opts);
          component.set('v.defaultValue', opts[0].value);
          this.disabledButton(component);
        }
      }
    });
    $A.enqueueAction(action);
  },
  checkAlertStatus: function(component) {
    var action = component.get('c.statusAlert');
    action.setParams({
      'alertId': component.get('v.recordId')
    });

    action.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        var discardOrManage = response.getReturnValue().split('//');
        if(discardOrManage[0] === 'true') {
          component.set('v.alertDiscarded', response.getReturnValue());
        } else if(discardOrManage[1] === 'true') {
          component.set('v.alertManaged', response.getReturnValue());
        }
      }
    });
    $A.enqueueAction(action);
  },
  discardAlerts: function(component) {
    var action = component.get('c.updateAlerts');
    action.setParams({
      'alertId': component.get('v.recordId'),
      'reason': component.find('reasons').get('v.value'),
      'comments': component.find('comments').get('v.value')
    });
    action.setCallback(this, function(response) {
      console.log('STATE -> ' + response.getState());
      if (response.getState() === 'SUCCESS') {
        console.log('Discarded');
      }
    });
    $A.enqueueAction(action);
  },
  disabledButton: function(component) {
    var reasons = component.get('v.defaultValue');
    if (reasons === undefined || reasons === '') {
      component.set('v.buttonDisabled', true);
    } else {
      component.set('v.buttonDisabled', false);
    }
  }
});