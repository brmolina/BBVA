({  
    doInit : function(cmp, event, helper){
        var accountId = cmp.get("v.recordId");
        var numberOfDeals = cmp.get("c.getNumberDeals");
        numberOfDeals.setParams({
            "accId" : accountId,
        });

        numberOfDeals.setCallback(this, function(response){
            if(response.getState() === "SUCCESS"){
                var resultData = JSON.parse(response.getReturnValue());
                cmp.set("v.numberRecords", resultData);
            }
        });
        $A.enqueueAction(numberOfDeals);
    },
    
    navigateToMyComponent : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:TopWonDealsWrapper",
            componentAttributes: {
                generalView : false,
                recordId : component.get("v.recordId"),
                numberRecordsView : null,
                header : true
            }
        });
        evt.fire();
    }
})