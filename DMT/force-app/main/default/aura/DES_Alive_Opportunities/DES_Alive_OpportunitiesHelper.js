({
  getTableData: function (cmp, event, helper) {
    //alert('>>>>> countriesToDisplay: ' + cmp.get("v.countriesToDisplay"));
    console.log('>>>>> cmp : ' + cmp)
    var action = cmp.get('c.getData');
    action.setParams({ tableSize: '5', countriesToDisplay: cmp.get('v.countriesToDisplay'), roleHierarchy: cmp.get('v.roleHierarchy'),gmRolVery: cmp.get('v.gmRolVery') });
    action.setCallback(this, $A.getCallback(function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var resultData = JSON.parse(response.getReturnValue());
        console.log('>>>>> resultData:');
        console.log(resultData);
        cmp.set('v.myData', resultData);
      } else if (state === "ERROR") {
        var errors = response.getError();
        console.error(errors);
      }
    }));
    $A.enqueueAction(action);
  },
  getUserISOCode: function (cmp) {
    var action = cmp.get("c.getCurrentUserISOCode");
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var storeResponse = response.getReturnValue();
        // set current user information on userInfo attribute
        cmp.set("v.userISOCode", storeResponse);
      }
    });
    $A.enqueueAction(action);
  }
})