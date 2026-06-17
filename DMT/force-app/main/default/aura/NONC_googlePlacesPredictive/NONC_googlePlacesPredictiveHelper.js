({
  callServer: function(component, method, callback, params) {
    var action = component.get(method);
    if (params) {
      action.setParams(params);
    }

    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        // pass returned value to callback function
        callback.call(this, response.getReturnValue());
      } else if (state === 'ERROR') {
        // generic error handler
        var errors = response.getError();
        if (errors) {
          console.log('Errors', errors);
          if (errors[0] && errors[0].message) {
            throw new Error('Error' + errors[0].message);
          }
        } else {
          throw new Error('Unknown Error');
        }
      }
    });

    $A.enqueueAction(action);
  },
  fireComponentEvent: function(component, event, helper, objResponse) {
    // Get the component event by using the
    // name value from aura:registerEvent

    var cmpEvent = component.getEvent('cmpEventGoogle');

    cmpEvent.setParams({
      'addressType': component.get('v.addressType'),
      'city': objResponse[0].location.City,
      'street': objResponse[0].location.Street,
      'country': objResponse[0].location.Country,
      'state': objResponse[0].location.State,
      'postalCode': objResponse[0].location.PostalCode
    });

    cmpEvent.fire();
  }
});