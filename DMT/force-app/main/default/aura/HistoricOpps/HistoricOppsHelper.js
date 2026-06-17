({
  getTableData: function (cmp) {
    var actionOpps = cmp.get('c.getOpps');
    actionOpps.setParams({
      "tableSize": cmp.get('v.tableSize'),
      "accId": cmp.get('v.recordId')
    });

    actionOpps.setCallback(this, function (response) {
      if (response.getState() === "SUCCESS") {
        var resultData = JSON.parse(response.getReturnValue());
        cmp.set("v.data", resultData);
      }
    });
    $A.enqueueAction(actionOpps);
  },
  navigateGoBackAccount : function(cmp, event, helper) {
    cmp.find("nav").navigate({
        type: "standard__recordPage",
        attributes: {
            recordId: cmp.get("v.recordId"),
            objectApiName: "Account",
            actionName: "view"
        }
    });
  }
})