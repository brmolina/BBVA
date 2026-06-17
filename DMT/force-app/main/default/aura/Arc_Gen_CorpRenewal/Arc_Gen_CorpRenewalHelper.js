({
  fetchAccHelper: function(component, event, helper) {
    let data = component.get('v.data');
    var action = component.get('c.fetchAccounts');
    action.setParams({
      recordId: data.id
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var currentData = component.get('v.arceList');
        var newData = currentData.concat(response.getReturnValue());
        component.set('v.arceList', newData);
      }
    });
    $A.enqueueAction(action);
  },
  setColumns: function(component) {
    var action = component.get('c.buildDynamicColumns');
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var columns = JSON.parse(response.getReturnValue());
        component.set('v.mycolumns', columns);
      }
    });
    $A.enqueueAction(action);
  }
});