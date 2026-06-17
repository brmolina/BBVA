({
  haveNPSContact: function (cmp) {
    var haveNPSContactsFunc = cmp.get("c.haveNPSContacts");

    haveNPSContactsFunc.setCallback(this, function(response) {
      if(response.getState() === "SUCCESS") {
        console.log('success call');
        var resultData = JSON.parse(response.getReturnValue());
        cmp.set("v.isOpen2", resultData[0].isEmpty);
      }
    });
    $A.enqueueAction(haveNPSContactsFunc);
  },

  completeTask: function (cmp) {
    var completeTaskFunc = cmp.get("c.completeTask");

    completeTaskFunc.setCallback(this, function(response) {
      if(response.getState() === "SUCCESS") {
        console.log('success call');
        cmp.set("v.isOpen2", false);
      }
    });
    $A.enqueueAction(completeTaskFunc);
  }
})