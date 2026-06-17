({

    getTableData: function (cmp) {
        var accountId = cmp.get("v.recordId");
        var periodTime = cmp.get("v.period");
        var nRecords = cmp.get("v.numberRecords");
        var relatedDeals = cmp.get("c.getTopWonDeals");
        relatedDeals.setParams({
            "tableSize" : nRecords,
            "accId" : accountId,
            "timeParam" : periodTime
        });

        relatedDeals.setCallback(this, function(response){
            if(response.getState() === "SUCCESS"){
                var resultData = JSON.parse(response.getReturnValue());
                cmp.set("v.data", resultData);
            }
        });
        $A.enqueueAction(relatedDeals);
    }
    
})