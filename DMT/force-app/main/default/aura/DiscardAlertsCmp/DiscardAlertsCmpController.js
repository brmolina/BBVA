({//eslint-disable-line
  doInit: function(component, event, helper) {
    helper.checkAlerts(component);
    helper.fetchDiscardReasons(component, 'altm__BBVA_rejection_reason_desc__c');
  },
  closeModel: function(component, event, helper) {
    component.set('v.isModalOpen', false);
    history.back();//eslint-disable-line
  },
  submitDetails: function(component, event, helper) {
    helper.discardAlerts(component);
  },
  changeValue: function(component, event, helper) {
    helper.disabledButton(component);
  },
  closeComponent: function(component, event, helper) {
    component.set('v.isModalOpen', false);
    history.back();//eslint-disable-line
  }
});