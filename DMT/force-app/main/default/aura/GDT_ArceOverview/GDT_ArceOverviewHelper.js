({
  fetchAccHelper: function(component, event, helper) {
    var action = component.get('c.fetchAccounts');
    action.setParams({
      recordId: component.get('v.recordId')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var currentData = component.get('v.acctList');
        var newData = currentData.concat(response.getReturnValue());
        component.set('v.acctList', newData);
        component.set('v.data', newData);
        component.set('v.showTable', true);
      }
    });
    $A.enqueueAction(action);
  },
  sortBy: function(field, reverse, primer) {
    var key = primer
      ? function(x) {
        return primer(x[field]);
      }
      : function(x) {
        return x[field];
      };
    return function(a, b) {
      a = key(a);
      b = key(b);
      return reverse * ((a > b) - (b > a));
    };
  },
  handleSort: function(cmp, event) {
    var sortedBy = event.getParam('fieldName');
    var sortDirection = event.getParam('sortDirection');
    var data = cmp.get('v.acctList');
    var cloneData = data.slice(0);
    cloneData.sort((this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1)));

    cmp.set('v.acctList', cloneData);
    cmp.set('v.sortDirection', sortDirection);
    cmp.set('v.sortedBy', sortedBy);
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