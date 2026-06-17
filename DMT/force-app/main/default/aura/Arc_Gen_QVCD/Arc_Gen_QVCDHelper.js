({
  hinit: function(component, event) {
    var resp;
    var action = component.get('c.getConfiguration');
    action.setParams({
      'recordId': component.get('v.recordId')
    });
    action.setCallback(this, function(response) {
      let state = response.getState();
      if (state === 'SUCCESS') {
        resp = response.getReturnValue();
        if (resp.status === 'SUCCESS') {
          let rRec = resp.config.readRecords === 'TRUE' ? true : false;
          component.set('v.permissionEdit', rRec);
          component.set('v.showButton', resp.config.showSwitchIcon === 'TRUE');
          component.set('v.tableConfName', resp.config.tableConfName);
        } else {
          this.toastMessage(resp.status, resp.errorMessage);
        }
      } else {
        this.toastMessage($A.get('$Label.c.Arc_Gen_Error_Parrilla_Message'), $A.get('$Label.c.Arc_Gen_ApexCallError'));
      }
    });
    $A.enqueueAction(action);
  },
  toastMessage: function(status, errorMessage) {
    switch (status) {
      case 'SUCCESS':
        var toastSuccess = $A.get('e.force:showToast');
        toastSuccess.setParams({
          'title': $A.get('$Label.c.Arc_Gen_Toast_Success_Title'),
          'type': 'success',
          'mode': 'sticky',
          'duration': '8000',
          'message': $A.get('$Label.c.Arc_Gen_Toast_Success')
        });
        toastSuccess.fire();
        break;
      case 'ERROR':
        var toastError = $A.get('e.force:showToast');
        toastError.setParams({
          'title': 'Error!',
          'type': 'error',
          'mode': 'sticky',
          'duration': '8000',
          'message': $A.get('$Label.c.Arc_Gen_Toast_Unknown_Error') + ' ' + errorMessage
        });
        toastError.fire();
        break;
    }
  }
});