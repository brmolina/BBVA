({
  init: function(component, event, helper) {
    helper.hinit(component, event);
  },
  onSubmit: function(component, event, helper) {
    component.set('v.insertSubmit', true);
    event.preventDefault();
    component.find('permChecker').checkEditPermission(component.get('v.accHasAId'))
      .then($A.getCallback(function() {
        helper.honSubmit(component, event, helper);
      }))
      .catch($A.getCallback(function(errorMsg) {
        helper.showErrorToast(errorMsg);
      }));
  },
  closeError: function(component, event, helper) {
    component.set('v.error', false);
  },
  handleChange: function(component, event, helper) {
    component.set('v.selectedChild', event.getParam('value'));
    component.set('v.editMode', 'edit');
    component.set('v.recordShow', true);
  },
  handleSuccess: function(component, event, helper) {
    helper.deactivateValidFlag(component)
      .then(function() {
        return helper.updateLimitsFromService(component, event, helper, event.getParam('id'));
      })
      .then(function() {
        if (component.get('v.changeStatus')) {
          $A.get('e.force:refreshView').fire();
        }
        component.set('v.insertSubmit', false);
        var toastEvent = $A.get('e.force:showToast');
        toastEvent.setParams({
          'type': 'SUCCESS',
          'title': $A.get('$Label.c.Arc_Gen_Toast_Success_Title'),
          'message': $A.get('$Label.c.Arc_Gen_Record_Update_Success'),
          'duration': 5000
        });
        toastEvent.fire();
        component.find('overlayLib').notifyClose();
        component.destroy();
      })
      .catch(function(err) {
        component.set('v.insertSubmit', false);
        helper.showErrorToast(err);
        helper.updateStatusLimitPers(component);
        component.find('overlayLib').notifyClose();
      });
  }
});