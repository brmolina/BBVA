({
	getTableData : function(cmp) {
		var action = cmp.get('c.getData');
        action.setParams({ famProd : cmp.get('v.familyProduct')});
		action.setCallback(this, $A.getCallback(function (response) {
			var state = response.getState();
			if (state === "SUCCESS") {
                var resultData = JSON.parse(response.getReturnValue());
                console.log('>>>>> resultData:');
                console.log(resultData);
				cmp.set('v.myData', resultData);
			} else if (state === "ERROR") {
				var errors = response.getError();
				console.error(errors);
			}
		}));
		$A.enqueueAction(action);
	},
    getUserISOCode: function(cmp){
        var action = cmp.get("c.getCurrentUserISOCode");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
               // set current user information on userInfo attribute
                cmp.set("v.userISOCode", storeResponse);
            }
        });
        $A.enqueueAction(action);
    }
})