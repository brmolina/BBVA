({
  getTableInfo: function(component, event, helper) {
    var action = component.get('c.getTableData');
    action.setParams({
      recordId: component.get('v.recordId')
    });
    action.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        var resp = JSON.parse(response.getReturnValue());
        component.set('v.columns', resp.columns);
        component.set('v.rows', resp.rows);
        component.set('v.currency', resp.currencyVal);
        component.set('v.unit', resp.unit);
        component.set('v.showButton', resp.showButton === 'true' ? true : false);
      } else {
        component.set('v.showTable', false);
      }
    });
    $A.enqueueAction(action);
  },
  showModalCmp: function(component, event, helper) {
    var parameters = {
      'accHasId': component.get('v.recordId'),
      'tableType': 'groupStructure',
      'relatedName': 'arce__Hotel_Projections__r',
      'sObjectType': 'arce__hotel_projection__c',
      'apexClassSave': 'Arc_Gen_ValidateHotelProjInfo_Service',
      'fieldsApiName': component.get('v.fieldsApiName'),
      'comboClassName': 'Arc_Gen_HotelProjSaveCombo_Service'
    };
    $A.createComponent('c:Arc_Gen_RelatedTableManager_cmp', parameters, function(html, status, errorMessage) {
      if (status === 'SUCCESS') {
        component.find('overlayLibrary').showCustomModal({
          header: $A.get('$Label.c.Arc_Gen_ManageHotelProj'),
          body: html,
          showCloseButton: true,
          cssClass: 'slds-modal_large',
          closeCallback: function() {
            helper.getTableInfo(component, event, helper);
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