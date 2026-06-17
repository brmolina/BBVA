/* eslint-disable no-unused-expressions */
({
  doInit: function(component, event, helper) {
    helper.wait(component);
    var action = component.get('c.canbeRefreshedToolkit');
    var recordId = component.get('v.recordId');
    action.setParams({
      templateId: recordId
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var refresh = response.getReturnValue();
        if (String(refresh) === 'YES') {
          component.set('v.editable', true);
        } else {
          component.set('v.editable', false);
        }
      } else if (state === 'INCOMPLETE') {
        console.log('INCOMPLETE ', response);
      } else if (state === 'ERROR') {
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            console.error('Error message: ' + errors[0].message);
          }
        } else {
          console.error('Unknown error');
        }
      }
      helper.doneWaiting(component);
    });
    $A.enqueueAction(action);
  },
  refreshInfo: function(component, event, helper) {
    helper.wait(component);
    var action = component.get('c.refreshToolkit');
    var recordId = component.get('v.recordId');
    action.setParams({
      templateId: recordId
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        helper.showToast('success', 'Template has been refreshed with Client Sustainability Information', '');

      } else if (state === 'INCOMPLETE') {
        console.log('INCOMPLETE ', response);
      } else if (state === 'ERROR') {
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            console.error('Error message: ' + errors[0].message);
          }
        } else {
          console.error('Unknown error');
        }
      }
      helper.doneWaiting(component);
      helper.closeDialog();
      $A.get('e.force:refreshView').fire();
    });
    $A.enqueueAction(action);
  },
  wait: function(component) {
    component.set('v.waiting', true);
  },

  doneWaiting: function(component) {
    component.set('v.waiting', false);
  },
  closeDialog: function() {
    $A.get('e.force:closeQuickAction').fire();
  },
  showToast: function(type, title, message) {
    var toastEvent = $A.get('e.force:showToast');
    toastEvent.setParams({
      title: title,
      message: message,
      duration: 5000,
      key: 'info_alt',
      type: type,
      mode: 'dismissible'
    });
    toastEvent.fire();
  }
});