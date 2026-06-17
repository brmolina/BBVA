({
	getCountries : function(cmp, event, helper) {
		var opt = [];
		var accPrm = cmp.get("v.accountId");
		var act = cmp.get('c.getRelatedCountries');
		act.setParams({
			clientId : accPrm
		});
		act.setCallback(this, $A.getCallback(function (response) {
		var state = response.getState();
		if (state === "SUCCESS") {
			var resultData = response.getReturnValue();
			resultData.forEach(function(element) {
                opt.push({ value: element, label: element });
            });
			cmp.set('v.countrySelector', opt);
		} else if (state === "ERROR") {
			var errors = response.getError();
			console.error(errors);
		}
	    }));
	    $A.enqueueAction(act);
	},

	getMatrix : function(cmp, event, helper) {
		var accPrm = cmp.get("v.accountId");
		var act = cmp.get('c.getRelatedMatrix');
		act.setParams({
			clientId : accPrm
		});
		act.setCallback(this, $A.getCallback(function (response) {
		var state = response.getState();
		if (state === "SUCCESS") {
			var resultData = JSON.parse(response.getReturnValue());
			cmp.set('v.matrixParent', resultData);
		} else if (state === "ERROR") {
			var errors = response.getError();
			console.error(errors);
		}
	    }));
	    $A.enqueueAction(act);
	}

})