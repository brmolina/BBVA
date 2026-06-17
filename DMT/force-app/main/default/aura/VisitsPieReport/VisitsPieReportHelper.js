({
	getTableData: function (component) {
        let actionChart = component.get('c.getRowsData');
        actionChart.setParams({
            "clientId": component.get("v.recordId"),
        });

        actionChart.setCallback(this, $A.getCallback(function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let resultData = JSON.parse(response.getReturnValue());
                console.log(resultData);
                component.set('v.myData', resultData);
            } else if (state === "ERROR") {
                console.error(response.getError());
            }
        }));
        $A.enqueueAction(actionChart);
    },

    sortData: function (component, fieldName, sortDirection) {
        let data = component.get("v.myData");
        let reverseOrder = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverseOrder))
        component.set("v.myData", data);
    },
    sortBy: function (field, reverse, primer) {
        let key = primer ?
            function (x) { return primer(x[field]) } :
            function (x) { return x[field] };
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            a = key(a);
            b = key(b);
            let c = reverse * ((a > b) - (b > a));
            return a, b, c; //NOSONAR
        }
    },
    navigateGoBackAccountVisit: function (component, event, helper) {
        component.find("nav").navigate({
            type: "standard__recordPage",
            attributes: {
                recordId: component.get("v.recordId"),
                objectApiName: "PersonAccount",
                actionName: "view"
            }
        });
    }

})