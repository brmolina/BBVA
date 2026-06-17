({
  init: function(cmp, event, helper) {
    helper.hinit(cmp, event);
  },
  handleLoad: function(component) {
    component.set('v.showSpinner', false);
  },
  handleRowAction: function(component, event, helper) {
    component.set('v.showSpinner', true);
    var action = event.getParam('action');
    switch (action.name) {
      case 'edit':
        setTimeout($A.getCallback(function() {
          component.set('v.showModal', true);
        }), 2000);
        break;
    }
  },
  handleSubmit: function(component, event, helper) {
    event.preventDefault();
    helper.hhandleSubmit(component, event);
  },
  handleSaveSuccess: function(component, event, helper) {
    var toastEvent = $A.get('e.force:showToast');
    toastEvent.setParams({
      'type': 'SUCCESS',
      'title': $A.get('$Label.c.Arc_Gen_Toast_Success_Title'),
      'message': $A.get('$Label.c.Arc_Gen_Record_Update_Success')
    });
    toastEvent.fire();
    helper.hinit(component, event);
    component.set('v.showModal', false);
  },
  close: function(component) {
    component.set('v.showSpinner', true);
    setTimeout($A.getCallback(function() {
      component.set('v.showModal', false);
      component.set('v.showSpinner', false);
    }), 1000);
  }
});