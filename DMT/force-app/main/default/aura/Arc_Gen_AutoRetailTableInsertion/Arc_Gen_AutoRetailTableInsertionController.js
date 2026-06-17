({
  init: function(component, event, helper) {
    if (component.get('v.operationType') === 'edit') {
      component.set('v.spinner', true);
      helper.getDataToEdit(component, event, helper)
        .then(function() {
          component.set('v.spinner', false);
        });
    }
  },
  handleSuccess: function(component, event, helper) {
    helper.showToast('SUCCESS', $A.get('$Label.c.Arc_Gen_Record_Update_Success'));
    component.find('overlayLibra').notifyClose();
  },
  handleCancel: function(component, event, helper) {
    component.find('overlayLibra').notifyClose();
  },
  handleSave: function(component, event, helper) {
    component.set('v.spinner', true);
    helper.saveRecords(component, event, helper)
      .then(function() {
        component.set('v.spinner', false);
        helper.showToast('SUCCESS', $A.get('$Label.c.Arc_Gen_Record_Update_Success'));
        component.find('overlayLibra').notifyClose();
      })
      .catch(function(errorMessage) {
        component.set('v.spinner', false);
        helper.showToast('ERROR', $A.get('$Label.c.Lc_arce_autoRetailTable_SaveError') + ' - ' + $A.get('$Label.c.Arc_Gen_RatingError_ErrorCode') + errorMessage);
      });
  },
  handleDelete: function(component, event, helper) {
    component.set('v.spinner', true);
    helper.deleteRecord(component, event)
      .then(function() {
        component.set('v.spinner', false);
        helper.showToast('SUCCESS', $A.get('$Label.c.Lc_arce_autoRetailTable_DeleteRecordSuccess'));
        component.find('overlayLibra').notifyClose();
      })
      .catch(function(errorMessage) {
        component.set('v.spinner', false);
        helper.showToast('ERROR', $A.get('$Label.c.Lc_arce_autoRetailTable_SaveError') + ' - ' + $A.get('$Label.c.Arc_Gen_RatingError_ErrorCode') + errorMessage);
      });
  },
});