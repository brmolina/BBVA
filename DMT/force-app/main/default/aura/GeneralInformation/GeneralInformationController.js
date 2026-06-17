({
	handleSectionToggle: function (cmp, event) {
        var openSections = event.getParam('openSections');
        if (openSections.length === 0) {
            cmp.set('v.activeSectionsMessage', "All sections are closed");
        } else {
            cmp.set('v.activeSectionsMessage', "Open sections: " + openSections.join(', '));
        }
    },
    handleSubmit : function(component, event, helper) {
        event.preventDefault(); // Prevent default submit
        var fields = event.getParam("fields");
        fields['Description'] = 'This is a default description'; // Prepopulate Description field
        component.find('createAccountForm').submit(fields); // Submit form
    },
    navToRecord : function (component, event, helper) {
        var navEvt = $A.get('e.force:navigateToSObject');
        navEvt.setParams({
            'recordId': component.get('v.account.Id')
        });
            navEvt.fire();
    },
    editRecord : function(component, event, helper) {
        helper.showHide(component);
    },
    handleSuccess : function(component, event, helper) {
        var toastEvent = $A.get('e.force:showToast');
        toastEvent.setParams({'title': 'Success!','message': "The property's info has been updated.",'type': 'success'});
        toastEvent.fire();
        helper.showHide(component);
    },
    handleCancel : function(component, event, helper) {
        helper.showHide(component);
        event.preventDefault();
    }
})