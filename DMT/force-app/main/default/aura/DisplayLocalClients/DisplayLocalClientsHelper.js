({
  getData: function (cmp, helper) {
    var action1 = cmp.get('c.getData');
    action1.setParams({ clientId: cmp.get("v.globalClientID"), country: cmp.get("v.countryOfProspect") });
    action1.setCallback(this, $A.getCallback(function (response) {
      var status = response.getState();
      if (status === "SUCCESS") {
        var result = JSON.parse(response.getReturnValue());
        cmp.set('v.myData', result);
      } else if (status === "ERROR") {
        var error = response.getError();
        console.error(error);
      }
    }));
    $A.enqueueAction(action1);
  }
})