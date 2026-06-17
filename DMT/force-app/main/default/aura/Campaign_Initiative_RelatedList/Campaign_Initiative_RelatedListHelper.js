({
  getTableData: function (cmp) {
    var accountId = cmp.get('v.recordId');
    var familyProd = cmp.get ('v.familyParam');
    var tableSizeP = cmp.get('v.tableSize');
    var relatedCampaigns = cmp.get('c.relatedCampaigns');
    relatedCampaigns.setParams({
      "tableSize" : tableSizeP,
      "accId" : accountId,
      "family" : familyProd
    });

    relatedCampaigns.setCallback(this, function(response) {
      if(response.getState() === "SUCCESS") {
        var resultData = JSON.parse(response.getReturnValue());
        cmp.set("v.data", resultData);
      }
    });
    $A.enqueueAction(relatedCampaigns);
  }
})