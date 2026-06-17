({
  callFinalizeRaip: function(component, arceId) {
    const action = component.get('c.finalizePrerating');

    action.setParams({ arceId });

    return new Promise($A.getCallback(function(resolve, reject) {
      action.setCallback(this, function(response) {
        let state = response.getState();

        if (state === 'SUCCESS') {
          resolve();
        } else {
          reject(response.getError());
        }
      });

      $A.enqueueAction(action);
    }));
  },
  validatePrerating: function(component, arceId) {
    component.set('v.loading', true);
    const action = component.get('c.validatePrerating');

    action.setParams({ arceId });

    return new Promise($A.getCallback(function(resolve, reject) {
      action.setCallback(this, function(response) {
        let state = response.getState();

        if (state === 'SUCCESS') {
          resolve();
        } else {
          reject(response.getError()[0]);
        }
      });

      $A.enqueueAction(action);
    }));
  },
  ratingProcessOK: function(component, event) {
    // Declare event outside promise as it appears to be undefined if
    // fetched from inside the promise (bug in Salesforce?).

    component.set('v.loading', false);
    component.set('v.errorMessage', '');

    // Success toast.
    const toastEvent = $A.get('e.force:showToast');
    toastEvent.setParams({
      title: $A.get('$Label.c.Arc_Gen_Toast_Success'),
      message: $A.get('$Label.c.Arc_Gen_FinalizePreratingSuccess'),
      type: 'success',
      duration: 3000
    });
    toastEvent.fire();

    window.location.reload();

  },
  cancelRating: function(component, message) {
    component.set('v.loading', false);
    component.set('v.errorMessage', message);
  },
  getRecalcRating: function(component, acchasAnalisisId) {
    var action = component.get('c.getRecalculateRating');
    action.setParams({
      accHasAnalisysId: acchasAnalisisId,
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = response.getReturnValue();
        var message = resp.split(';')[0];
        component.set('v.ahaObj', JSON.parse(resp.split(';')[1]));

        if (message === 'Show') {
          component.set('v.show', true);
        } else {
          component.set('v.show', false);
          this.showToast('WARNING', message);
        }
      }
    });
    $A.enqueueAction(action);
  },
  showToast: function(type, message) {
    var toastEventUE = $A.get('e.force:showToast');
    toastEventUE.setParams({
      title: '',
      type: type,
      mode: 'dismissible',
      duration: '5000',
      message: message
    });
    toastEventUE.fire();
  },
  limitAdvisor: function(component, event, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      let ahaObj = component.get('v.ahaObj');
      let financialStatementId = ahaObj.arce__ffss_for_rating_id__r.arce__financial_statement_id__c;
      let workFlowIRP = ahaObj.arce__IRP_Workflow__c;

      if (workFlowIRP === 'IRP' && financialStatementId) {
        var action = component.get('c.callLimitAdvisor');
        action.setParams({
          aHaId: ahaObj.Id
        });

        action.setCallback(this, function(response) {
          var state = response.getState();
          if (state === 'SUCCESS') {
            var resp = response.getReturnValue();
            if (resp) {
              resolve();
            } else {
              reject();
            }
          } else if (state === 'ERROR') {
            var errors = response.getError();
            reject(errors && errors[0] && errors[0].message || 'Unexpected error occurred while calling Limit Advisor.');
          }
        });

        $A.enqueueAction(action);
      } else {
        resolve();
      }
    }));
  }
});