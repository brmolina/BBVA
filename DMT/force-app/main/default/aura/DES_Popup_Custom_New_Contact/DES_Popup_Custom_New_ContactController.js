({
    onCloseModal: function (component, event, helper) {
        helper.closeModal(component, event, helper);
    },
    doInit: function (component, event, helper) {
        helper.getDomain(component);
    },
})