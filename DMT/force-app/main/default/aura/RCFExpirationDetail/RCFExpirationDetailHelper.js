({
	getTableDataCnt : function(cmp, helper) {
		var actionController = cmp.get('c.getDataDetails');
        actionController.setParams({ clientId : cmp.get("v.recordId") });
		actionController.setCallback(this, $A.getCallback(function (response) {
			var state = response.getState();
			if (state === "SUCCESS") {
                var resultData = JSON.parse(response.getReturnValue());
				cmp.set('v.myData', resultData);
                helper.sortDataTable(cmp, "expDate", "desc");
			} else if (state === "ERROR") {
				var errors = response.getError();
				console.error(errors);
			}
		}));
		$A.enqueueAction(actionController);
	},
    sortDataTable: function (cmp, fieldName, directionData) {
        var data = cmp.get("v.myData");
        var arribaOabajo = directionData !== 'asc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortBy(fieldName, arribaOabajo))
        cmp.set("v.myData", data);
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
    },
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
            function(x) {return x[field]};
        reverse = !reverse ? 1 : -1;
        return function (abc, bc) {
            abc = key(abc);
            bc = key(bc);
            var c = reverse * ((abc > bc) - (bc > abc));
            return abc, bc, c; //NOSONAR
        }
    },
    navigateGoBackAccount : function(cmp, event, helper) {
        cmp.find("nav").navigate({
            type: "standard__recordPage",
            attributes: {
                recordId: cmp.get("v.recordId"),
                objectApiName: "PersonAccount",
                actionName: "view"
            }
        });
    },
    navigateGoBackFamilyDummy: function(cmp, event, helper) {
        // New version since api 43, cambiado a nombre dummy porque da fallos por caché, vuelta a la versión del e.force:navigateToCMP
        cmp.find("nav").navigate({
            type: "standard__component",
            attributes: {
                componentName: "c__ViewFamilySection" },
            state: {
                c__familyChecked: cmp.get("v.familyParam"),
                c__recordId: cmp.get("v.recordId")
            }

        });
    },
    navigateGoBackFamily : function(cmp, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:ViewFamilySection",
            componentAttributes: {
                familyChecked: cmp.get("v.familyParam"),
                recordId: cmp.get("v.recordId")
            }
        });
        evt.fire();
    }
})