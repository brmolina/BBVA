({
    doInit: function(component, event, helper) {
    helper.doInitHelper(component, event, helper);
  },
  handleCountryChange: function(component, event, helper) {
    helper.getClientsOpts(component, event, helper);
  },
  handleClientChange: function(component, event, helper) {
    component.set('v.isLoading', true);
    helper.callParentSubsidiary(component)
    .then((result) => {
        component.set('v.isLoading', false);
        helper.handleRatingSystem(component, event, helper);
      })
      .catch((errorMessage) => {
        helper.showToastEvent('Error', errorMessage, 'error');
        helper.handleRSError(component, errorMessage, true);
        component.set('v.isLoading', false);
      });
  },
  handleDone: function(component, event, helper) {
    helper.notifyParent(component);
  },
  refreshViewForm: function(component, event, helper) {
    const clientSlctdTemp = component.get('v.clientSlctd');
    component.set('v.clientSlctd', null);
    component.set('v.clientSlctd', clientSlctdTemp); // NOSONAR
  }
});