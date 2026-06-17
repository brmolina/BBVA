({
  saveRecords: function(component, event, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var action = component.get('c.insertRecords');
      var parameters = {
        'agencyName': component.get('v.agencyName'),
        'agenciesNumber': parseInt(component.get('v.agenciesNumber')),
        'brand': component.get('v.brand'),
        'bankRisk': parseFloat(component.get('v.bankRisk')),
        'stockDays': parseFloat(component.get('v.stockDays')),
        'totalUnitsYear1': parseFloat(component.get('v.totalUnitsYear1')),
        'totalUnitsYear2': parseFloat(component.get('v.totalUnitsYear2')),
        'stockRotationYear1': component.get('v.stockRotationYear1'),
        'stockRotationYear2': component.get('v.stockRotationYear2'),
        'accHasAnalysisId': component.get('v.accHasAnalysisId'),
        'operationType': component.get('v.operationType'),
        'tableType': component.get('v.tableType'),
        'year1': component.get('v.year1'),
        'year2': component.get('v.year2'),
        'selectedRowId': component.get('v.selectedRowId'),
        'standardYear1Id': component.get('v.standardYear1Id'),
        'standardYear2Id': component.get('v.standardYear2Id')
      };
      action.setParams({
        data: parameters
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          resolve();
        } else {
          reject(response.getError()[0].message);
        }
      });
      $A.enqueueAction(action);
    }));
  },
  getDataToEdit: function(component, event, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var action = component.get('c.getData');
      action.setParams({
        'selectedRowId': component.get('v.selectedRowId'),
        'year1': component.get('v.year1'),
        'year2': component.get('v.year2')
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var retrievedData = response.getReturnValue();
          component.set('v.agencyName', retrievedData.agencyName);
          component.set('v.agenciesNumber', retrievedData.agenciesNumber);
          component.set('v.brand', retrievedData.brand);
          component.set('v.bankRisk', retrievedData.bankRisk);
          component.set('v.stockDays', retrievedData.stockDays);
          component.set('v.totalUnitsYear1', retrievedData.totalUnitsYear1);
          component.set('v.totalUnitsYear2', retrievedData.totalUnitsYear2);
          component.set('v.stockRotationYear1', retrievedData.stockRotationYear1);
          component.set('v.stockRotationYear2', retrievedData.stockRotationYear2);
          resolve();
        } else {
          reject(response.getError()[0].message);
        }
      });
      $A.enqueueAction(action);
    }));
  },
  deleteRecord: function(component, event) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var action = component.get('c.deleteRecord');
      action.setParams({
        'selectedRowId': component.get('v.selectedRowId')
      });
      action.setCallback(this, function(response) {
        if (response.getState() === 'SUCCESS') {
          resolve();
        } else {
          reject(response.getError()[0].message);
        }
      });
      $A.enqueueAction(action);
    }));
  },
  showToast: function(type, message) {
    var toastEventUE = $A.get('e.force:showToast');
    toastEventUE.setParams({
      'title': '',
      'type': type,
      'duration': '8000',
      'message': message
    });
    toastEventUE.fire();
  }
});