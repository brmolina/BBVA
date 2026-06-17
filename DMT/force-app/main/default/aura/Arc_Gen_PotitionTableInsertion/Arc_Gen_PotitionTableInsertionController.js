({
  init: function(component, event, helper) {
    helper.hinit(component, event);
  },
  onSubmit: function(component, event, helper) {
    event.preventDefault();
    helper.honSubmit(component, event);
  },
  handleChange: function(component, event, helper) {
    component.set('v.selectedChild', event.getParam('value'));
    component.set('v.editMode', 'edit');
  },
  handleSuccess: function(component, event, helper) {
    helper.showToast('SUCCESS', $A.get('$Label.c.Arc_Gen_Record_Update_Success'));
    component.find('overlayLibra').notifyClose();
  }
});