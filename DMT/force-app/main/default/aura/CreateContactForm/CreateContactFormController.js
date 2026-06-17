({
  doInit: function (component, event, helper) {
    helper.setInitialValues(component);
    helper.getDomain(component);
    const sObjectName = component.get('v.sObjectName');
    if (sObjectName === 'Contact') {
      helper.getContactData(component, event, helper);
    }
  },
  handleSubmitCreate: function (component, event, helper) {
    helper.handleSubmit(component, event, 'Insert', true);
  },
  handleSubmitUpdate: function (component, event, helper) {
    helper.handleSubmit(component, event, 'Update', false);
  },
  confirmFields: function (component, event, helper) {
    helper.handleSubmit(component, event, 'Update', true);
  },
  onCloseModal: function (component, event, helper) {
    helper.closeModal(component, event, helper);
  },
  handleGoBackFirstScreen: function (component, event, helper) {
    helper.goBackFirstScreen(component, event, helper);
  },
  handleComponentEvent: function (component, event, helper) {
    var recordIDFromEvent = event.getParam('recordByEvent');

    if (recordIDFromEvent !== undefined && recordIDFromEvent != null) {
      component.set('v.selectedOwnerFiltered', recordIDFromEvent);
    }
    var recordAccIDFromEvent = event.getParam('recordAccByEvent');

    if (recordAccIDFromEvent !== undefined && recordAccIDFromEvent != null) {
      component.set('v.selectedAccountFiltered', recordAccIDFromEvent);
    }
  },
});