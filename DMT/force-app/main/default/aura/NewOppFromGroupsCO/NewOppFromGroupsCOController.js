({
	doInit: function (cmp, event, helper) {
		helper.getCountries(cmp, event, helper);
		helper.getMatrix(cmp, event, helper);
	},

	handleChange : function (cmp, event, helper) {
		var opti = [];
		var accParm = cmp.get("v.accountId");
		var selectedOptValue = event.getParam("value");
		var actn = cmp.get('c.getRecords');
		actn.setParams({
			clientId : accParm,
			selectedValue : selectedOptValue
		});

		actn.setCallback(this, $A.getCallback(function (response) {
		var stt = response.getState();
		if (stt === "SUCCESS") {
			var resltData = JSON.parse(response.getReturnValue());
            for(var i in resltData) {
				opti.push({ value: resltData[i].idMatrix, label: resltData[i].matrixName });
            }
			cmp.set('v.subsidiarySelector', opti);
		} else if (stt === "ERROR") {
			var errs = response.getError();
			console.error(errs);
		}
	    }));
	    $A.enqueueAction(actn);
	},

	matrixRedirect :  function (cmp, event, helper) {
		var matrId = cmp.get("v.matrixParent.idMatrix");
	    var urlEvnt = $A.get("e.force:navigateToURL");
	    var urlStr = window.location.href;
    	var basURL = urlStr.substring(0, urlStr.indexOf("/s"));
	    urlEvnt.setParams({
	      "url": basURL + '/lightning/r/Account/' + matrId + '/view'
	    });
	    urlEvnt.fire();
	},

	continueFunction : function (cmp, event, helper) {
		var idRedirct = cmp.get("v.selectedOption");
		var urlStr = window.location.href;
    	var basURL = urlStr.substring(0, urlStr.indexOf("/s"));
		if(idRedirct.length > 0) {
			var urlEvnt = $A.get("e.force:navigateToURL");
			urlEvnt.setParams({
				"url": basURL + '/lightning/r/Account/' + idRedirct + '/view'
	    });
	    urlEvnt.fire();
		} else {
			var toastEvnt = $A.get("e.force:showToast");
			toastEvnt.setParams({
			    title: "Hello!",
			    message: "Please, select one subsidiary",
			    type: "warning"
			});
			toastEvnt.fire();
		}
	},

	handleAccChange : function(cmp, event, helper) {
		var selectedOptValue = event.getParam("value");
		cmp.set('v.selectedOption', selectedOptValue);
        cmp.set('v.subsidiaryId', selectedOptValue);
	},

	cancelFunction : function(cmp, event, helper) {
		console.log('>>>>>>>>>cancelFunction');
		$A.get("e.force:closeQuickAction").fire();
        $A.get("e.force:refreshView").fire();
    },

})