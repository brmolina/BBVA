({
	doInit: function (cmp, event, helper) {
		helper.getCountries(cmp, event, helper);
		helper.getMatrix(cmp, event, helper);
	},

	handleChange : function (cmp, event, helper) {
		var options = [];
		var accParam = cmp.get("v.accountId");
		var selectedOptionValue = event.getParam("value");
		var action = cmp.get('c.getRecords');
		action.setParams({
			clientId : accParam,
			selectedValue : selectedOptionValue
		});

		action.setCallback(this, $A.getCallback(function (response) {
		var state = response.getState();
		if (state === "SUCCESS") {
			var resultData = JSON.parse(response.getReturnValue());
            for(var i in resultData) {
				options.push({ value: resultData[i].idMatrix, label: resultData[i].matrixName });
            }
			cmp.set('v.subsidiarySelector', options);
		} else if (state === "ERROR") {
			var errors = response.getError();
			console.error(errors);
		}
	    }));
	    $A.enqueueAction(action);
	},

	matrixRedirect :  function (cmp, event, helper) {
		var matrixId = cmp.get("v.matrixParent.idMatrix");
	    var urlEvent = $A.get("e.force:navigateToURL");
	    var urlString = window.location.href;
    	var baseURL = urlString.substring(0, urlString.indexOf("/s"));
	    urlEvent.setParams({
	      "url": baseURL + '/lightning/r/Account/' + matrixId + '/view'
	    });
	    urlEvent.fire();
	},

	continueFunction : function (cmp, event, helper) {
		var idRedirect = cmp.get("v.selectedOption");
		var initiatives = cmp.get("v.initiatives");
		var urlString = window.location.href;
    	var baseURL = urlString.substring(0, urlString.indexOf("/s"));
		if(initiatives) {
			cmp.set("v.idFilial", idRedirect);
		}
		else if(idRedirect.length > 0) {
			var urlEvent = $A.get("e.force:navigateToURL");
			urlEvent.setParams({
				"url": baseURL + '/lightning/r/Account/' + idRedirect + '/view'
	    });
	    urlEvent.fire();
		} else {
			var toastEvent = $A.get("e.force:showToast");
			toastEvent.setParams({
			    title: "Hello!",
			    message: "Please, select one subsidiary",
			    type: "warning"
			});
			toastEvent.fire();
		}
	},

	handleAccChange : function(cmp, event, helper) {
		var selectedOptionValue = event.getParam("value");
		cmp.set('v.selectedOption', selectedOptionValue);
		cmp.set("v.idFilial", selectedOptionValue);
	},

	cancelFunction : function(cmp, event, helper) {
		console.log('>>>>>>>>>cancelFunction');
		$A.get("e.force:closeQuickAction").fire();
        $A.get("e.force:refreshView").fire();
    },

})