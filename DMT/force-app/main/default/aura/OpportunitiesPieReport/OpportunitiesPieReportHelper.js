({
    getTableData: function (component) {
        let actionGetData = component.get('c.getRowsData');
        actionGetData.setParams({
            "clientId": component.get("v.recordId"),
            "family": component.get("v.familyParam"),
            "stageOption": component.get("v.stageOption"),
            // "byProduct": component.get("v.byProduct"),
            // "byCountryBooking": component.get("v.byCountry"),
            "countryClient": component.get("v.countryParam")
        });
        console.log('familyParam detail helper' + component.get("v.familyParam"));
        actionGetData.setCallback(this, $A.getCallback(function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let resultGetData = JSON.parse(response.getReturnValue());
                component.set('v.myData', resultGetData);
            } else if (state === "ERROR") {
                console.error(response.getError());
            }
        }));
        $A.enqueueAction(actionGetData);
    },
    sortData: function (component, fieldName, sortDirection) {
        let data = component.get("v.myData");
        let reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortBy(fieldName, reverse))
        component.set("v.myData", data);
    },
    goBackToFamily: function (component, event, helper) {
        let eventSf = $A.get("e.force:navigateToComponent");
        eventSf.setParams({
            componentDef: "c:ViewFamilySection",
            componentAttributes: {
                familyChecked: component.get("v.familyParam"),
                recordId: component.get("v.recordId")
            }
        });
        eventSf.fire();
    },
    sortBy: function (fieldToOrderb, reverse, primer) {
        let keyToOrder = primer ?
            function (x) { return primer(x[fieldToOrderb]) } :
            function (x) { return x[fieldToOrderb] };
        //checks if the two rows should switch places
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            a = keyToOrder(a);
            b = keyToOrder(b);
            let c = reverse * ((a > b) - (b > a));
            return a, b, c; //NOSONAR
        }
    },
    goBackToAccount: function (component, event, helper) {
        component.find("nav").navigate({
            type: "standard__recordPage",
            attributes: {
                recordId: component.get("v.recordId"),
                objectApiName: "PersonAccount",
                actionName: "view"
            }
        });
    },
    navigateGoBackFamilyDummy: function (component, event, helper) {
        // New version since api 43, cambiado a nombre dummy porque da fallos por caché, vuelta a la versión del e.force:navigateTocomponent
        component.find("nav").navigate({
            type: "standard__component",
            attributes: {
                componentName: "c__ViewFamilySection"
            },
            state: {
                c__familyChecked: component.get("v.familyParam"),
                c__recordId: component.get("v.recordId")
            }

        });
    }
})