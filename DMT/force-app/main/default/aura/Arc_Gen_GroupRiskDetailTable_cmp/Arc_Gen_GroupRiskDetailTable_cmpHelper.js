({
  createGroupRiskTable: function(component, event, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var action = component.get('c.createGroupRiskTable');
      action.setParams({
        accHasId: component.get('v.hasRecordId'),
        configurationId: component.get('v.configurationId')
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var res = response.getReturnValue();
          var wrapperData = JSON.parse(res);
          if (wrapperData.table.lstRows.length > 0) {
            component.set('v.jsonTable', wrapperData.table);
            resolve();
          } else {
            if (wrapperData.lblEmptyTable !== null) {
              component.set('v.message', wrapperData.lblEmptyTable);
            }
            reject();
          }
        } else {
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  doComponent: function(component) {
    $A.createComponent(
      'dwp_dv:Dynamic_Table_cmp',
      {
        'jsonSettup': component.get('v.jsonTable'),
        'objApiName': component.get('v.objApiName'),
        'tableType': component.get('v.tableType')
      },
      function(newCmp, status, errorMessage) {
        if (status === 'SUCCESS') {
          var contentToDisplay = [];
          contentToDisplay.push(newCmp);
          component.set('v.body', contentToDisplay);
          component.set('v.spinner', 'false');
        }
      }
    );
  },
  showErrorToast: function(message) {
    const toastEvent = $A.get('e.force:showToast');
    toastEvent.setParams({
      'title': $A.get('$Label.c.Arc_Gen_UpdateLimitsError'),
      'message': message,
      'type': 'error'
    });
    toastEvent.fire();
  }
});