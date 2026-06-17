({
  saveFields: function(component, event, helper) {
    event.preventDefault();
    var fields = event.getParam('fields');
    helper.putZero(fields);
    component.find('EditForm').submit(fields);
  },
  handleSaveSuccess: function(component, event, helper) {
    var toastEvent = $A.get('e.force:showToast');
    toastEvent.setParams({
      'type': 'SUCCESS',
      'title': $A.get('$Label.c.Arc_Gen_Toast_Success_Title'),
      'message': $A.get('$Label.c.Arc_Gen_Record_Update_Success')
    });
    toastEvent.fire();
    component.find('overlayLibEdition').notifyClose();
  }
});