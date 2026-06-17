({//eslint-disable-line
  doInit: function(component, event, helper) {
    helper.checkAlertStatus(component);
    helper.fetchDiscardReasons(component, 'altm__BBVA_rejection_reason_desc__c');
  },
  submitDetails: function(component, event, helper) {
    helper.discardAlerts(component);
    var navEvt = $A.get("e.force:navigateToSObject");
    navEvt.setParams({
      "recordId": component.get('v.recordId'),
      "slideDevName": "related"
    });
    setTimeout(function() {
      $A.get('e.force:refreshView').fire();
      navEvt.fire();
    }, 1000);
  },
  changeValue: function(component, event, helper) {
    helper.disabledButton(component);
  }
});