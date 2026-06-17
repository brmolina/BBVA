({
	getInfo : function(cmp, evt, helper){
		var action = cmp.get("c.getInfoWithoutDefaultValues");
		action.setParams({
			"recordId" : cmp.get('v.recordId')
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				var ret = response.getReturnValue();
				if(ret.hasOLI){
					var objectInput = {
						'IdOppLineItem':ret.IdOppLineItem,
						'approvalMethod':ret.approvalMethod,
						'ProductCode':ret.ProductCode
					};
					cmp.set('v.Product',ret.Product);
					cmp.set('v.objectInput',objectInput);
					cmp.set('v.isOk',ret.isOk); 
				}
				cmp.set('v.priceIndicator',ret.priceIndicator);
				cmp.set('v.hasOLI',ret.hasOLI);
				cmp.set('v.isLoad',true);
			}
		}); 
		$A.enqueueAction(action);
	}
})