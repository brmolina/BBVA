({
  getRevenuesInfo: function (cmp, evt, helper) {
    var action2 = cmp.get('c.getRevenuesData');
    action2.setParams({
      recordId: cmp.get('v.recordId'),
      objectName: cmp.get('v.sObjectName'),
      country: cmp.get('v.country')
    });
    console.log('::::country ' + cmp.get('v.country'));
    action2.setCallback(this, function (response) {
      if (cmp.isValid() && response.getState() === 'SUCCESS') {
        console.log('Funcion revenuesInfo');
        var resultData = JSON.parse(response.getReturnValue());
        cmp.set('v.data', resultData);
      } else {
        var errors = response.getError();
        var errorMessage = errors[0].message;
        var toastError = $A.get('e.force:showToast');
        toastError.setParams({
          'title': 'Error!',
          'type': 'error',
          'message': errorMessage
        });
        toastError.fire();
      }

    });
    $A.enqueueAction(action2);
  },

  getUserISOCode: function (cmp) {
    var action = cmp.get("c.currentUserISOCode");
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var storeResponse = response.getReturnValue();
        // set current user information on userInfo attribute
        cmp.set("v.userISOCode", storeResponse);
      }
    });
    $A.enqueueAction(action);
  },

})