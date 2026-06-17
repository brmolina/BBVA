({
  checkForms: function(component) {
    if (JSON.parse(component.get('v.formsIds')).length === 0) {
      component.set('v.receivedForms', false);
    } else {
      component.set('v.receivedForms', true);
    }
  },

  completeForms: function(component) {
    var action = component.get('c.updateForms');
    var size = 0;
    component.set('v.disabled', true);
    action.setParams({
      'formsId': component.get('v.formsIds'),
    });
    action.setCallback(this, function(response) {
        if (response.getState() === 'SUCCESS') {
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
        component.set('v.disabled', false);
    });
    $A.enqueueAction(action);
  },

  checkRole: function(component) {
    var action = component.get('c.checkRole');
    action.setCallback(this, function(response) {
        if (response.getState() === 'SUCCESS') {
            component.set('v.role', response.getReturnValue());
        }
    });
    $A.enqueueAction(action);
  }
})