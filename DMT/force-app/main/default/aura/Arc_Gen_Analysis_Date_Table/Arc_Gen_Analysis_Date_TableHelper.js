({
  getCurrencyUnits: function(component5, event, helper) {
    var action = component5.get('c.getTableData');
    action.setParams({
      recordId: component5.get('v.recordId')
    });
    action.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        var resp = JSON.parse(response.getReturnValue());
        component5.set('v.currency', resp.currencyVal);
        component5.set('v.unit', resp.unit);
        component5.set('v.showButton', resp.showButton === 'true' ? true : false);
      }
    });
    $A.enqueueAction(action);
  },
  showModalCmp: function(component6, event, helper) {
    var parameters = {
      'accHasId': component6.get('v.recordId'),
      'tableType': component6.get('v.tableType'),
      'relatedName': component6.get('v.relatedName'),
      'sObjectType': component6.get('v.sObjectType'),
      'apexClassSave': component6.get('v.apexClassSave'),
      'fieldsApiName': component6.get('v.fieldsApiName'),
      'filterTable': component6.get('v.filterTable'),
      'comboClassName': 'Arc_Gen_Date_SaveCombo_Service'
    };
    $A.createComponent('c:Arc_Gen_RelatedTableManager_cmp', parameters, function(html, status, errorMessage) {
      if (status === 'SUCCESS') {
        component6.find('overlayLibrary').showCustomModal({
          header: $A.get('$Label.c.Arc_Gen_ManageHotelAnalysisDate'),
          body: html,
          showCloseButton: true,
          cssClass: 'slds-modal_large',
          closeCallback: function() {
            component6.set('v.viewTable', false);
            helper.getCurrencyUnits(component6, event, helper);
            component6.set('v.viewTable', true);
          }
        });
      } else {
        helper.toastMessages(status, errorMessage);
      }
    });
  },
  toastMessages: function(status, message2) {
    var toastMe = $A.get('e.force:showToast');
    toastMe.setParams({
      'title': '',
      'type': 'status',
      'mode': 'sticky',
      'duration': '8000',
      'message': message2
    });
    toastMe.fire();
  }
});