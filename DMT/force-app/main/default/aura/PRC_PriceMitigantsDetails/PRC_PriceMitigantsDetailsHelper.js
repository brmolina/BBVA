({
  executeGetMitigants : function(component, actionMitigant, callback) {
    // Promise Execute action against the server
    return new Promise(function(resolve, reject) {
      actionMitigant.setCallback(this,
        function(response) {
          var state = response.getState();
          if (state === 'SUCCESS') {
            resolve(response.getReturnValue());
          } else if (state === 'ERROR') {
            var errors1 = response.getError();
            if (errors1) {
              if (errors1[0] && errors1[0].message) {
                reject(Error('Error message: '
                    + errors1[0].message));
              }
            } else {
              reject(Error('Unknown error'));
            }
          }
        });
      $A.enqueueAction(actionMitigant);
    });
  },
  callDetails : function(component, helper, pricingDetailsId) {
    var actionCard = component.get('c.getMitigants');
    actionCard.setParams({ 'priceDetailId': pricingDetailsId });
    var promiseaction = this.executeGetMitigants(component, actionCard);
    return promiseaction.then(
      $A.getCallback(function(result) {
          component.set('{!v.mitigantList}', result);
      }),
      $A.getCallback(function(error) {
      })
    ).catch(function(e) {
    });
  },
  deleteMitigant: function(component, helper, codMitigant) {
    var actionDelete = component.get('c.deleteMitigant');
    actionDelete.setParams({'mitigantId': codMitigant});
    var promiseaction = this.executeGetMitigants(component, actionDelete);
    return promiseaction.then(
      $A.getCallback(function(result) {
        helper.callDetails(component, helper, component.get('v.pricingDetailsId'));
        console.log('Delete sucessful');
      }),
      $A.getCallback(function(error) {
      })
    ).catch(function(e) {
    });
  }
})