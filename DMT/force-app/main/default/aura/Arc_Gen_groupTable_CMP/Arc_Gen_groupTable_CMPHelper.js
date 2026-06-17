({
  fetchData: function(component, event, helper) {
    let accounts = component.get('v.accounts');
    component.set('v.columns', [{
      label: $A.get('{!$Label.c.Lc_arce_GroupStructure}'),
      fieldName: 'customer',
      type: 'text'
    }, {
      label: 'Customer Number',
      fieldName: 'CustomerNumber',
      type: 'text'
    }]);
    let action = component.get('c.retrieveData');
    action.setParams({
      'accounts': accounts
    });
    action.setCallback(this, function(response) {
      let state = response.getState();
      let data = response.getReturnValue();
      if (!data) {
        component.set('v.showmessage', false);
        component.set('v.showtable', false);
      }
      if (state === 'SUCCESS') {
        var jsonaccounts = [];
        data.forEach(function(element) {
          if (element) {
            var jsoncolumn = new Object();
            jsoncolumn.customer = element.name;
            jsoncolumn.CustomerNumber = element.accNumber;
            jsonaccounts.push(jsoncolumn);
          }
        });
        component.set('v.data', jsonaccounts);
        component.set('v.showmessage', false);
        component.set('v.showtable', true);
      }
    });
    $A.enqueueAction(action);
  }
});