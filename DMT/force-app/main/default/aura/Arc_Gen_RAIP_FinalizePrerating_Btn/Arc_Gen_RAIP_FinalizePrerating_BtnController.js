({
  fetchIdFromUrl: function(component, event, helper) {
    var arceId = '';
    var pathArray = window.location.href.split('/');
    for (let aux = 0; aux < pathArray.length; aux++) {
      if (pathArray[aux] === 'arce__Analysis__c') {
        arceId = pathArray[aux + 1];
      }
    }

    component.set('v.hasRecordId', arceId);
    var inputAttrs = component.get('v.inputAttributes');
    var acchasAnalisisId = inputAttrs.recordId;
    helper.getRecalcRating(component, acchasAnalisisId);
  },

  handleConfirm: function(component, event, helper) {
    // Declare event outside promise as it appears to be undefined if
    // fetched from inside the promise (bug in Salesforce?).
    component.set('v.loading', true);
    component.set('v.errorMessage', '');
    helper.limitAdvisor(component, event)
      .then(function() {
        return helper.validatePrerating(component, component.get('v.hasRecordId'));
      })
      .then(function() {
        return helper.callFinalizeRaip(component, component.get('v.hasRecordId'));
      })
      .then(function() {
        helper.ratingProcessOK(component, event);
      })
      .catch(function(error) {
        helper.cancelRating(component, error.message);
      })
      .finally(function() {
        component.set('v.loading', false);
    });
  },
  handleCancel: function(component, event, helper) {

    // Emit refresh event.
    $A.get('e.force:refreshView').fire();
  }
});