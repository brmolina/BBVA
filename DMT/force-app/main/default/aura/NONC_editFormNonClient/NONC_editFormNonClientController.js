({//eslint-disable-line
  closeModal: function(component, event, helper) {
    helper.closeModal(component, event, helper);
  },
  backModal: function(component, event, helper) {
    helper.backModal(component, event, helper);
  },
  handleOnSubmitForm: function(component, event, helper) {
    helper.handleOnSubmitForm(component, event, helper);
  },
  handleSave: function(component, event, helper) {
    document.getElementById('btnEnviarFrm').click();
  },
  handleSuccess: function(component, event, helper) {
    helper.handleSuccess(component, event, helper);
  },
  doInit: function(component, event, helper) {
    helper.cargarFielSet(component, event, helper);
  }
});