({
  doInit: function (component, event, helper) {
    var RecordId = component.get('v.recordId');
    var action = component.get('c.getLocalClient');
    action.setParams({
      'recordId': RecordId
    });
    action.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        component.set('v.pais', response.getReturnValue());
        if (response.getReturnValue().length > 0) {
          if (response.getReturnValue().length > 1) {
            window.location.replace('https://' + window.location.hostname + '/lightning/r/' + response.getReturnValue()[1].Cib_Client__c + '/related/Local_Clients__r/view');
          } else {
            window.location.replace('https://' + window.location.hostname + '/lightning/r/Local_Client__c/' + response.getReturnValue()[0].Id + '/view');
          }
        }
      }
    });
    $A.enqueueAction(action);
  },
  cancelar: function (component, event, helper) {
    $A.get('e.force:closeQuickAction').fire();
  },
})