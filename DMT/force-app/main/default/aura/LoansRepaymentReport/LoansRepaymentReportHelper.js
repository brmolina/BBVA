({
    getPageReference: function (component) {
        const myPageRef = component.get("v.pageReference");
        component.set("v.recordId", myPageRef.state.c__recordId);
        component.set("v.operation", myPageRef.state.c__operation);
    },
    getTableData: function (component) {
        let apex = component.get('c.getRowsData');
        apex.setParams({
            "clientId": component.get("v.recordId"),
            "operationType": component.get("v.operation"),
        });
        apex.setCallback(this, $A.getCallback(function (response) {
            const state = response.getState();
            if (state === "SUCCESS") {
                let resultValues = JSON.parse(response.getReturnValue());
                console.log(resultValues);
                component.set('v.myData', resultValues);
            } else if (state === "ERROR") {
                console.error(response.getError());
            }
        }));
        $A.enqueueAction(apex);
    },
    sortData: function (component, fieldName, sortDirection) {
        let data = component.get("v.myData");
        let reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortBy(fieldName, reverse))
        component.set("v.myData", data);
    },
    sortBy: function (field, reverse, primer) {
        let key = primer ?
            function (x) { return primer(x[field]) } :
            function (x) { return x[field] };
        //checks if the two rows should switch places
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            a = key(a);
            b = key(b);
            let c = reverse * ((a > b) - (b > a));
            return a, b, c;//NOSONAR
        }
    },
    navToAccount: function (component, event, helper) {
        component.find("nav").navigate({
            type: "standard__recordPage",
            attributes: {
                recordId: component.get("v.recordId"),
                objectApiName: "PersonAccount",
                actionName: "view"
            }
        });
    },
    navToFamily: function (component, event, helper) {
        let evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef: "c:ViewFamilySection",
            componentAttributes: {
                familyChecked: 'GF',
                recordId: component.get("v.recordId")
            }
        });
        evt.fire();
    }
})