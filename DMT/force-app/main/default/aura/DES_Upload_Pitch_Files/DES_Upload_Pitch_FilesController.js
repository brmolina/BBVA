({
    doInit: function (component, event, helper) {
        var uploadedFileses = event.getParam('files');
        helper.getuploadedFiles(component, uploadedFileses, false);
    },
    handleUploadFinished: function (cmp, event, helper) {
        // Get the list of uploaded files
        var uploadedFileses = event.getParam('files');
        console.log(uploadedFileses);
        cmp.set('v.nullcontrol', true);
        helper.getuploadedFiles(cmp, uploadedFileses, true);
    },
    saveForm: function (component, event, helper) {
        var actionClicked = event.getSource().getLocalId();
        var navigate = component.get('v.navigateFlow');
        navigate(actionClicked);
    }
})