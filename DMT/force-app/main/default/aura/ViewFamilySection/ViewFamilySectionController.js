({
  onInit: function(cmp, evt, helper) {
    helper.firstPromise(cmp, evt, helper).then(
              $A.getCallback(function (result) {
                  var action = cmp.get("c.fetchUser");
                  action.setCallback(this, function(response) {
                      var state = response.getState();
                      if (state === "SUCCESS") {
                          helper.retrieveParams(cmp, evt, helper);
                          var storeResponse = response.getReturnValue();
                         // set current user information on userInfo attribute
                          cmp.set("v.userInfo", storeResponse);
                      }
                  });
                  $A.enqueueAction(action);
              }),
              $A.getCallback(function (error) {
                  console.error('Error calling action getUrlIp with state: ' + error.message);
              })
          ).catch(function (e) {});
  },
    onClickButton: function(cmp, evt, helper) {
      helper.navigateGoBackAccount(cmp, evt, helper);
    },
    onRender: function(cmp, evt, helper) {
      helper.reloadRecord(cmp, evt, helper);
    }
})