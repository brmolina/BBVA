({//eslint-disable-line
  fetchDiscardReasons: function(component, fieldName) {
    var actionLocal = component.get('c.getselectOptions');
    actionLocal.setParams({
      'objObject': component.get('v.objAlert'),
      'fld': fieldName
    });
    var optsLocal = [];
    actionLocal.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        var allValuesLocal = Object.values(response.getReturnValue());
        var allLabel = Object.keys(response.getReturnValue());
        for (var i = 0; i < allValuesLocal.length; i++) {
          optsLocal.push({
            class: 'optionClass',
            label: allLabel[i],
            value: allValuesLocal[i]
          });
        }
        if (optsLocal.length > 0) {
          component.set('v.optionsDiscard', optsLocal);
          component.set('v.defaultValue', optsLocal[0].value);
          this.disabledButton(component);
        }
      }
    });
    $A.enqueueAction(actionLocal);
  },
  checkAlerts: function(component) {
    if (JSON.parse(component.get('v.alertsIds')).length === 0) {
      component.set('v.receivedAlerts', false);
    } else {
      component.set('v.receivedAlerts', true);
    }
  },
  discardAlerts: function(component) {
    var actionLocal = component.get('c.updateAlerts');
    var size = 0;
    actionLocal.setParams({
      'alertIds': component.get('v.alertsIds'),
      'reason': component.find('reasons').get('v.value'),
      'comments': component.find('comments').get('v.value')
    });
    actionLocal.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        console.log('Alerts Discarded');
        component.set('v.managedResult', response.getReturnValue());
        size = response.getReturnValue().length;
      }
      if (size <= 0){
          history.back();//eslint-disable-line
          component.set('v.isModalOpen', false);
      } else {
      	component.set('v.isModalOpen', false);
        component.set('v.managed', true);
      }
    });
    $A.enqueueAction(actionLocal);
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