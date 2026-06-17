({
  getCurrencyUnits: function(component3, event, helper) {
    var action = component3.get('c.getTableData');
    action.setParams({
      recordId: component3.get('v.recordId')
    });
    action.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        var resp = JSON.parse(response.getReturnValue());
        component3.set('v.currency', resp.currencyVal);
        component3.set('v.unit', resp.unit);
        component3.set('v.showButton', resp.showButton === 'true' ? true : false);
      }
    });
    $A.enqueueAction(action);
  },
  showModalCmp: function(component4, event, helper) {
    var parameters = {
      'accHasId': component4.get('v.recordId'),
      'tableType': component4.get('v.tableType'),
      'relatedName': component4.get('v.relatedName'),
      'sObjectType': component4.get('v.sObjectType'),
      'apexClassSave': component4.get('v.apexClassSave'),
      'fieldsApiName': component4.get('v.fieldsApiName'),
      'filterTable': component4.get('v.filterTable'),
      'comboClassName': 'Arc_Gen_Category_SaveCombo_Service'
    };
    $A.createComponent('c:Arc_Gen_RelatedTableManager_cmp', parameters, function(html, status, errorMessage) {
      if (status === 'SUCCESS') {
        component4.find('overlayLibrary').showCustomModal({
          header: $A.get('$Label.c.Arc_Gen_ManageHotelAnalysisCategory'),
          body: html,
          showCloseButton: true,
          cssClass: 'slds-modal_large',
          closeCallback: function() {
            component4.set('v.viewTable', false);
            helper.getCurrencyUnits(component4, event, helper);
            component4.set('v.viewTable', true);
          }
        });
      } else {
        helper.toastMessages(status, errorMessage);
      }
    });
  },
  toastMessages: function(status, message1) {
    var toastMe = $A.get('e.force:showToast');
    toastMe.setParams({
      'title': '',
      'type': 'status',
      'mode': 'sticky',
      'duration': '8000',
      'message': message1
    });
    toastMe.fire();
  }
});