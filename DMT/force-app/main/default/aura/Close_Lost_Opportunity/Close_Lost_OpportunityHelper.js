({
  getStatusOfAction: function(component, field) {
    var action = component.get('c.getPickListValues');
    action.setParams({
      'iField': field
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if(state === 'SUCCESS') {
        var opts = [];
        var allValues = response.getReturnValue();
        for(var key in allValues) {
          opts.push({
            value: key,
            label: allValues[key]
          });
          component.set('v.status_of_action_options', opts);
        }
      }
    });
    $A.enqueueAction(action);
  },

  getReasonsLost: function(component, field) {
    var action = component.get('c.getPickListValues');
    action.setParams({
      'iField': field
    });

    action.setCallback(this, function(response) {
      var state = response.getState();
      if(state === 'SUCCESS') {
        var opts = [];
        var allValues = response.getReturnValue();
        for(var key in allValues) {
          if(component.get('v.reasons_lost_value') === undefined || component.get('v.reasons_lost_value') === null) {
            component.set('v.reasons_lost_value', key);
          }
          if(key === component.get('v.reasons_lost_value')) {
            opts.push({
              value: key,
              label: allValues[key],
              selected: true
            });
          } else {
            opts.push({
              value: key,
              label: allValues[key]
            });
          }
        }
        component.set('v.reasons_lost_options', opts);
      }
    });
    $A.enqueueAction(action);
  },
  gtOpportunity: function(component) {
    var action = component.get('c.gtOpportunity');
    action.setParams({
      'iRecordId': component.get('v.inputAttributes').recordId
    })
    action.setCallback(this, function(response) {
      var state = response.getState();
      if(state === 'SUCCESS') {
        component.set('v.opportunity', response.getReturnValue());
        component.set('v.confirm_opportunity', response.getReturnValue().confirmOpp);
        component.set('v.reasons_lost_value', response.getReturnValue().iReason);
        component.set('v.description_value', response.getReturnValue().iDescription);
        component.set('v.isMoreThan10M', response.getReturnValue().moreThan10M);
        if(component.get('v.confirm_opportunity') === true) {
          component.set('v.save_disabled', false);
        }
      }
    });
    $A.enqueueAction(action);
  }
})