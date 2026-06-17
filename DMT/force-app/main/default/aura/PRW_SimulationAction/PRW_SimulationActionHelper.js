({
  doInit: function (cmp, helper) {
    var action = cmp.get('c.isClientSpain');
    action.setParams({
      recordId: cmp.get('v.recordId')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var success = response.getReturnValue();

        if (success) {
          helper.helperMethod(cmp, helper);
        } else {
          cmp.set('v.clientNotSpain', true);
        }

      } else if (state === 'INCOMPLETE') {
        console.log('INCOMPLETE', response);
      } else if (state === 'ERROR') {
        var errors = response.getError();
        console.error('Error message: ' + errors[0].message);
      }
    });
    $A.enqueueAction(action);

  },
  helperMethod: function (cmp, helper) {
    var recordId = cmp.get("v.recordId");
    var url = window.location+'';
    var getCucos = cmp.get('c.isClientGroup');
    getCucos.setParams({
      accId: cmp.get('v.recordId')
    });
    var promise = helper.promisifySimAction(getCucos);
    return promise.then(
      $A.getCallback(function (result) {
        if(result) {
          var evt = $A.get("e.force:navigateToComponent");
          evt.setParams({
            componentDef: "c:PRW_SelectCucoFromGroup",
            componentAttributes: {
              recordId: recordId,
              lastUrl: url
            }
          });
          evt.fire();
        } else {
          let urlVar = '/lightning/n/PRW_LightningTab/?&c__accountId=' + recordId;
          var eUrl = $A.get("e.force:navigateToURL");
          eUrl.setParams({
              "url": urlVar
          });
          eUrl.fire();
        }
      }),
      $A.getCallback(function (error) {
        console.error('Error calling action "' + getCucos + '" with state: ' + error.message);
      })
    ).catch(function (e) {});
  },
  promisifySimAction: function (actionSim) {
    return new Promise((resolve, reject) => {
      actionSim.setCallback(this, function (response) {
        const statusSimInfo = response.getState();
        if(statusSimInfo === 'SUCCESS') {
          resolve(response.getReturnValue());
        } else if (statusInfo === 'ERROR') {
          var errorsInfo = response.getError();
          if(errorsInfo) {
            if(errorsInfo[0] && errorsInfo[0].message) {
              reject(Error('Error message: ' + errorsInfo[0].message));
            }
          } else {
            reject(Error('Unknown error'));
          }
        }
      });
      $A.enqueueAction(actionSim);
    });
  }
})