({
    doInit: function(component, event, helper) {
        helper.checkRole(component);
        helper.checkForms(component);
    },
    closeModel: function(component, event, helper) {
        component.set('v.isModalOpen', false);
        history.back();
    },
    submitDetails: function(component, event, helper) {
        helper.completeForms(component);
    },
    closeComponent: function(component, event, helper) {
        component.set('v.isModalOpen', false);
        history.back();
    }
  });