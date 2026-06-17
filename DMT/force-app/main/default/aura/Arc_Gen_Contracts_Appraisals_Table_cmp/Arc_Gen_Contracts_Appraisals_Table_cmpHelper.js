({
  getCurrencyUnits: function(component, event, helper) {
    var action = component.get('c.getTableData');
    action.setParams({
      recordId: component.get('v.recordId')
    });
    action.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        var resp = JSON.parse(response.getReturnValue());
        component.set('v.currency', resp.currencyVal);
        component.set('v.unit', resp.unit);
        component.set('v.showButton', resp.showButton === 'true' ? true : false);
      }
    });
    $A.enqueueAction(action);
  },
  showModalCmp: function(component, event, helper) {
    var parameters = {
      'accHasId': component.get('v.recordId'),
      'tableType': component.get('v.tableType'),
      'relatedName': component.get('v.relatedName'),
      'sObjectType': component.get('v.sObjectType'),
      'apexClassSave': component.get('v.apexClassSave'),
      'fieldsApiName': component.get('v.fieldsApiName'),
      'filterTable': component.get('v.filterTable'),
      'comboClassName': 'Arc_Gen_Appraisals_SaveCombo_Service'
    };
    $A.createComponent('c:Arc_Gen_RelatedTableManager_cmp', parameters, function(html, status, errorMessage) {
      if (status === 'SUCCESS') {
        component.find('overlayLibrary').showCustomModal({
          header: $A.get('$Label.c.Arc_Gen_ManageHotelAppraisals'),
          body: html,
          showCloseButton: true,
          cssClass: 'slds-modal_large',
          closeCallback: function() {
            component.set('v.viewTable', false);
            helper.getCurrencyUnits(component, event, helper);
            component.set('v.viewTable', true);
          }
        });
      } else {
        helper.toastMessages(status, errorMessage);
      }
    });
  },
  toastMessages: function(status, message) {
    var toastMe = $A.get('e.force:showToast');
    toastMe.setParams({
      'title': '',
      'type': 'status',
      'mode': 'sticky',
      'duration': '8000',
      'message': message
    });
    toastMe.fire();
  }
});