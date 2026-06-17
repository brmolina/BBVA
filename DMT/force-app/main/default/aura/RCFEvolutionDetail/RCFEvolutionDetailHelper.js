({
	getTableData : function(cmp, helper) {
		var action1 = cmp.get('c.getDataReport');
		action1.setParams({ clientId : cmp.get("v.recordId") });
		action1.setCallback(this, $A.getCallback(function (response) {
			var status = response.getState();
			if (status === "SUCCESS") {
				var result = JSON.parse(response.getReturnValue());
				cmp.set('v.myData', result);
				helper.sortInfo(cmp, 'dateEv', 'desc');
			} else if (status === "ERROR") {
				var error = response.getError();
				console.error(error);
			}
		}));
		$A.enqueueAction(action1);
	},
    sortInfo: function (cmp, fieldName, sortDirection) {
        var data = cmp.get("v.myData");
        var direction = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortBy(fieldName, direction))
        cmp.set("v.myData", data);
    },
    sortBy: function (field, direction, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
            function(x) {return x[field]};
        //checks if the two rows should switch places
        direction = !direction ? 1 : -1;
        return function (a, b) {
            b = key(b);
            a = key(a);
            var c = direction * ((a > b) - (b > a));
            return a, b, c;//NOSONAR
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