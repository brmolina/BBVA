({
  saveFields: function(component, event, helper) {
    component.set('v.insertSubmit', true);
    event.preventDefault();
    component.find('permChecker').checkEditPermission(component.get('v.accHasAId'))
      .then($A.getCallback(function() {
        helper.hsaveFields(component, event);
      }))
      .catch($A.getCallback(function(errorMsg) {
        helper.showErrorToast(errorMsg);
      }));
  },
  closeError: function(component, event, helper) {
    component.set('v.error', false);
  },
  close: function(component, event, helper) {
    component.find('overlayLib').notifyClose();
  },
  handleSaveSuccess: function(component, event, helper) {
    helper.sumTypos(component)
      .then(function() {
        return helper.hhandleSaveSuccess(component);
      })
      .then(function() {
        return helper.updateAhaLimits(component, event, helper);
      })
      .then(function() {
        component.set('v.insertSubmit', false);
        var toastEvent = $A.get('e.force:showToast');
        toastEvent.setParams({
          'type': 'SUCCESS',
          'title': $A.get('$Label.c.Arc_Gen_Toast_Success_Title'),
          'message': $A.get('$Label.c.Arc_Gen_Record_Update_Success'),
          'duration': 5000
        });
        toastEvent.fire();
        if (component.get('v.changeStatus')) {
          $A.get('e.force:refreshView').fire();
          component.find('overlayLib').notifyClose();
          component.destroy();
        }
      })
      .catch(function(err) {
        component.set('v.insertSubmit', false);
        helper.showErrorToast(err);
        helper.updateStatusLimitPers(component);
      });
  }
});