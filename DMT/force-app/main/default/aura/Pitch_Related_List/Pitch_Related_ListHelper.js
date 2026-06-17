({
  getTableData: function (cmp) {
    var accountId = cmp.get('v.recordId');
    var familyProd = cmp.get ('v.familyParam');
    var tableSizeP = cmp.get('v.tableSize');
    var relatedPitches = cmp.get('c.relatedPitches');
    relatedPitches.setParams({
      "tableSize" : tableSizeP,
      "iAccountId" : accountId,
      "family" : familyProd
    });

    relatedPitches.setCallback(this, function(response) {
      if(response.getState() === "SUCCESS") {
        var resultData = JSON.parse(response.getReturnValue());
        cmp.set("v.data", resultData);
      }
    });
    $A.enqueueAction(relatedPitches);
  }
})