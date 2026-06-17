({
	getCountries : function(cmp, event, helper) {
		var option = [];
		var accP = cmp.get("v.accountId");
		var actn = cmp.get('c.getRelatedCountries');
		actn.setParams({
			clientId : accP
		});
		actn.setCallback(this, $A.getCallback(function (response) {
		var state = response.getState();
		if (state === "SUCCESS") {
			var resultData = response.getReturnValue();
			resultData.forEach(function(element) {
                option.push({ value: element, label: element });
            });
			cmp.set('v.countrySelector', option);
		} else if (state === "ERROR") {
			var errors = response.getError();
			console.error(errors);
		}
	    }));
	    $A.enqueueAction(actn);
	},

	getMatrix : function(cmp, event, helper) {
		var accP = cmp.get("v.accountId");
		var actn = cmp.get('c.getRelatedMatrix');
		actn.setParams({
			clientId : accP
		});
		actn.setCallback(this, $A.getCallback(function (response) {
		var state = response.getState();
		if (state === "SUCCESS") {
			var resultData = JSON.parse(response.getReturnValue());
			cmp.set('v.matrixParent', resultData);
		} else if (state === "ERROR") {
			var errors = response.getError();
			console.error(errors);
		}
	    }));
	    $A.enqueueAction(actn);
	}

})