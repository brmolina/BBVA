({
  hvalidate: function(component, event) {
    var inputAttributes = component.get('v.inputAttributes');
    var action = component.get('c.validateCustomer');
    action.setParams({
      accHasAId: inputAttributes.recordId
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = response.getReturnValue();
        if (resp.success === true && resp.gblResponse.length === 0 && resp.ratingStatus.length === 0) {
          component.set('v.show', false);
          component.set('v.validation', true);
          component.set('v.analysisType', resp.analysisType);
        } else if (resp.success === true && resp.gblResponse.length !== 0 && resp.ratingStatus.length === 0) {
          component.set('v.message', resp.gblResponse);
        } else if (resp.success === true && resp.ratingStatus.length !== 0) {
          component.set('v.show', false);
          var toastEvent = $A.get('e.force:showToast');
          toastEvent.setParams({
            'title': $A.get('{!$Label.c.Arc_Gen_ErrorMessage}'),
            'type': 'ERROR',
            'mode': 'sticky',
            'message': $A.get('{!$Label.c.Arc_Gen_ErrorValidRatingMessage}') + ' : ' + resp.ratingStatus + '.'
          });
          toastEvent.fire();
        } else {
          component.set('v.error', true);
          component.set('v.errorMessage', resp.responseError);
        }
      }
    });
    $A.enqueueAction(action);
  },
  toastMessageLev: function(component, type, message) {
    var resultsToast = $A.get('e.force:showToast');
    resultsToast.setParams({
      'title': '',
      'type': type,
      'message': message,
      'duration': '8000'
    });
    resultsToast.fire();
  }
});