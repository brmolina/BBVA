({
  doSelectedRow: function(component, helper, event) {
    var ffssId = event.getParam('recordId');
    var jsonTable = component.get('v.jsonTable');
    var action = component.get('c.getAnalyzedClient');
    action.setParams({
      jsonSetup: JSON.stringify(jsonTable),
      ffssId: ffssId
    });
    action.setCallback(this, function(response) {
      var resp = response.getReturnValue();
      var state = response.getState();
      if (state === 'SUCCESS') {
        var wrapperData = JSON.parse(resp.tableWrapper);
        component.set('v.idSelect', resp.ratingId);
        component.set('v.template', resp.templateName);
        component.set('v.jsonTable', wrapperData.table);
        component.set('v.view', true);
        component.set('v.success', 'yes');
        helper.doCreateTable(component);
      } else {
        component.set('v.success', 'no');
      }
    });
    $A.enqueueAction(action);
  },
  getInitData: function(component) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var recordId = component.get('v.hasRecordId');
      var action = component.get('c.getInitData');
      action.setParams({
        recordId: recordId
      });
      action.setCallback(this, function(response) {
        if (component.isValid() && response.getState() === 'SUCCESS') {
          var res = response.getReturnValue();
          if (res !== null) {
            component.set('v.ffssRatingId', res);
            resolve();
          } else {
            reject();
          }
        } else if  (response.getState() === 'ERROR') {
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  getJsonTable: function(component, helper) {
    var action = component.get('c.getJsonTable');
    action.setParams({
      ffssId: component.get('v.ffssRatingId')
    });
    action.setCallback(this, function(response) {
      if (component.isValid() && response.getState() === 'SUCCESS') {
        var res = response.getReturnValue();
        var wrapperData = JSON.parse(res);
        component.set('v.jsonTable', wrapperData.table);
        helper.doCreateTable(component);
      }
    });
    $A.enqueueAction(action);
  },
  doCreateTable: function(component) {
    $A.createComponent(
      'dwp_dv:Dynamic_Table_cmp',
      {
        'jsonSettup': component.get('v.jsonTable'),
        'objApiName': component.get('v.objApiName'),
        'tableId': component.get('v.tableId'),
        'tableType': component.get('v.tableType')
      },
      function(newCmp, status, errorMessage) {
        if (status === 'SUCCESS') {
          var contentToDisplay = [];
          contentToDisplay.push(newCmp);
          component.set('v.body', contentToDisplay);
          component.set('v.spinnerCmp', false);
        }
      }
    );
  }
});