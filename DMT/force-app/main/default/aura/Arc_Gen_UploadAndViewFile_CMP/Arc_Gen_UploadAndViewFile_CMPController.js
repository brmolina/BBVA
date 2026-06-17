({
  doInit: function(cmp, event, helper) {
    helper.helperMethod(cmp);
  },
  handleUploadFinished: function(cmp, event, helper) {
    var uploadedFiles = event.getParam('files');
    cmp.set('v.viewFile', false);
    helper.updateName(cmp, uploadedFiles[0].documentId);
  }
});