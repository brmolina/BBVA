({
  getTableInfo: function(component, event, helper) {
    var action = component.get('c.getTableInfo');
    action.setParams({
      accHasId: component.get('v.recordId')
    });
    action.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        var resp = JSON.parse(response.getReturnValue());
        component.set('v.columns', resp.columns);
        component.set('v.rows', resp.rowData);
      }
    });
    $A.enqueueAction(action);
  },
  showModalCmp: function(component, event, helper) {
    var parameters = {
      accHasId: component.get('v.recordId')
    };
    $A.createComponent('c:Arc_Gen_EvolPricesTableModal', parameters, function(
      html,
      status,
      errorMessage
    ) {
      if (status === 'SUCCESS') {
        component.find('overlayLibrary').showCustomModal({
          header: $A.get('$Label.c.Arc_Gen_ManageEvolMainProd'),
          body: html,
          showCloseButton: true,
          cssClass: 'slds-modal_small',
          closeCallback: function() {
            helper.getTableInfo(component, event, helper);
            html.destroy();
          }
        });
      }
    });
  }
});