({
  getTableData: function (cmp) {
    var contactId = cmp.get("v.recordId");
    var contactHistory = cmp.get("c.getContactHistory");
    console.log ("family = "+ contactId);
    contactHistory.setParams({
      "tableSize" : '6',
      "contactId" : contactId
    });

    contactHistory.setCallback(this, function(response) {
      if(response.getState() === "SUCCESS") {
        var resultData = JSON.parse(response.getReturnValue());
        console.log("resultData = "+ resultData);
        console.log("resultData = "+ resultData.year);
        console.log("resultData = "+ resultData.ownerName);
        cmp.set("v.data", resultData);
      }
    });
    $A.enqueueAction(contactHistory);
  }
})