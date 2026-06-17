({
	bringData : function(cmp, evt, helper) {
		var action = cmp.get("c.getIdProductByOpportunity");
		var OpportunityId = cmp.get("v.recordId");
		var ProductId;
		action.setParams({
			"IdOpportunity" : OpportunityId
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				if(response.getReturnValue()!=null){
					ProductId=response.getReturnValue()[0].Product2Id;
					cmp.set("v.ProductId",ProductId);
					var action2 = cmp.get("c.getParticipantDataByProduct");
					action2.setParams({
						"IdOpportunity" : OpportunityId,
						"IdProduct" : ProductId
					});
					action2.setCallback(this, function(response) {
						var state = response.getState();
						if (state === "SUCCESS") {
							cmp.set("v.rowsP", response.getReturnValue());
							if(response.getReturnValue().length !=0){
								cmp.set("v.refreshTable",true);
							}
						}
					});
					$A.enqueueAction(action2);
				}
			}
		});
		$A.enqueueAction(action);
	}
})