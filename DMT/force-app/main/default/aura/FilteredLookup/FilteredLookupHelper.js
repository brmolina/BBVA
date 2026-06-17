({
  searchHelper: function (component, event, getInputkeyWord) {
    var action;
    if (component.get('v.objectAPIName') === 'Product2') {
      action = component.get('c.fetchLookUpValuesFamily');
      action.setParams({
        'searchKeyWord': getInputkeyWord,
        'objectName': component.get('v.objectAPIName'),
        'strFilter': component.get('v.productFamily')
      });
    } else if (component.get('v.objectAPIName') === 'Opportunity') {
      action = component.get('c.fetchLookUpValuesDisclosure');
      action.setParams({
        'searchKeyWord': getInputkeyWord,
        'objectName': component.get('v.objectAPIName'),
        'strFilter': component.get('v.disclosureInfo')
      });
    } else {
      action = component.get('c.fetchLookUpValuesEmail');
      action.setParams({
        'searchKeyWord': getInputkeyWord,
        'objectName': component.get('v.objectAPIName')
      });
    }


    action.setCallback(this, function (response) {
      $A.util.removeClass(component.find('mySpinner'), 'slds-show');
      var state = response.getState();
      if (state === 'SUCCESS') {
        var storeResponse = response.getReturnValue();
        if (storeResponse.length === 0) {
          component.set('v.Message', 'No Result Found...');
        } else {
          component.set('v.Message', '');
        }

        component.set('v.listOfSearchRecords', storeResponse);
      }
    });

    $A.enqueueAction(action);
  },
  checkObjectOpen: function (component, objectOpen, response) {
    if (objectOpen === 'Contact') {
      component.set("v.selectedRecord.Name", response.getReturnValue().Owner.Name);
      component.set("v.selectedRecord.Id", response.getReturnValue().Owner.Id);
    } else if (objectOpen === 'Product2' || objectOpen === 'dwp_kitv__Visit_Topic__c') {
      component.set("v.selectedRecord.Id", response.getReturnValue().Id);
      component.set("v.selectedRecord.Name", response.getReturnValue().Name);
    } else {
      component.set("v.selectedRecord.Name", response.getReturnValue().Name);
      component.set("v.selectedRecord.Id", response.getReturnValue().Id);
    }
  },
  accountAction: function (component, event, objectOpen) {
    var action2 = component.get('c.getRelatedAccount');
    action2.setParams({
      "objectName": component.get("v.objectOpenForm"),
      "objectRecordId": component.get("v.recordId"),
    });
    action2.setCallback(this, function (response) {
      if (response.getState() === "SUCCESS") {
        var selectedAccountGetFromEvent = response.getReturnValue();
        var compEvent = component.getEvent('oSelectedRecordEvent');
        if (objectOpen === 'Contact') {
          component.set("v.selectedRecord.Name", response.getReturnValue().Account.Name);
          component.set("v.selectedRecord.Id", response.getReturnValue().AccountId);
                    var selectedAccount = { "Name": response.getReturnValue().Account.Name,
                                           "Id": response.getReturnValue().AccountId}
          compEvent.setParams({ 'recordAccByEvent': selectedAccount });
        } else {
          component.set("v.selectedRecord.Name", response.getReturnValue().Name);
          compEvent.setParams({ 'recordAccByEvent': selectedAccountGetFromEvent });
        }

        compEvent.fire();
      }
    });
    $A.enqueueAction(action2);
  }
});