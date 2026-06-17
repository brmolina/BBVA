({
	sectionTwo : function(component, event, helper) {
		helper.helperFun(component,event,"articleTwo");
	},
	sectionThree : function(component, event, helper) {
		helper.helperFun(component,event,"articleThree");
	},
	doInit: function(cmp, evt, helper){
		var action = cmp.get("c.getProduct2");
			action.setParams({
				"recordId":cmp.get("v.recordId")
			});
			action.setCallback(this, $A.getCallback(function (response) {
				var state = response.getState();
				if (state === "SUCCESS") {
					cmp.set("v.Prod2", response.getReturnValue());
				} else if (state === "ERROR") {
					var errors = response.getError();
					console.error(errors);
				}
			}));
			$A.enqueueAction(action);
	},
	handleSelectedEvent : function(cmp, evt, helper) {
	}
})