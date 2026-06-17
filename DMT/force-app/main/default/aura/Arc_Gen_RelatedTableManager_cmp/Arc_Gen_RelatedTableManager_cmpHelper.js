({
  combosValue: function(component, event, helper) {
    var action = component.get('c.getCombosValues');
    action.setParams({
      recordId: component.get('v.accHasId'),
      tableType: component.get('v.tableType')
    });
    action.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        var resp = JSON.parse(response.getReturnValue());
        if (resp.unit === $A.get('$Label.c.Arc_Gen_Unit')) {
          component.set('v.unit', '1');
        } else if (resp.unit === $A.get('$Label.c.Arc_Gen_Thousands')) {
          component.set('v.unit', '2');
        } else if (resp.unit === $A.get('$Label.c.Arc_Gen_Millions')) {
          component.set('v.unit', '3');
        }
        component.set('v.currency', resp.currencyVal);
      }
    });
    $A.enqueueAction(action);
  },
  saveCombos: function(component, event, helper, selectedOptionValue, comboVal) {
    var action = component.get('c.saveCombos');
    action.setParams({
      recordId: component.get('v.accHasId'),
      value: selectedOptionValue,
      combo: comboVal,
      className: component.get('v.comboClassName')
    });
    action.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        var resp = JSON.parse(response.getReturnValue());
        if (resp.saveStatus === 'false') {
          helper.toastMessages('ERROR', resp.saveMessage);
        }
      }
    });
    $A.enqueueAction(action);
  },
  toastMessages: function(status, message) {
    var toastMe = $A.get('e.force:showToast');
    toastMe.setParams({
      'title': '',
      'type': status,
      'mode': 'sticky',
      'duration': '8000',
      'message': message
    });
    toastMe.fire();
  }
});