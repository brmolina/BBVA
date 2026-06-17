({
	getInfo : function(cmp, evt, helper){
		var action = cmp.get("c.getInfoWithoutDefaultValues");
		action.setParams({
			"recordId" : cmp.get("v.recordId")
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
				if (state === "SUCCESS") {
				var ret = response.getReturnValue();
				var objectInput = {
					"IdOppLineItem":ret.IdOppLineItem,
					"approvalMethod":ret.approvalMethod,
					"ProductCode":ret.ProductCode
				};
				cmp.set("v.objectInput",objectInput);
				cmp.set("v.isLoad",true);
			}
		}); 
		$A.enqueueAction(action);
	}
})