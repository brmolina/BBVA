({
  getTableData : function(cmp) {
    var action = cmp.get('c.getRowsData');
        action.setParams({ clientId : cmp.get("v.recordId"),
                           family: cmp.get("v.familyParam")});
        console.log ('familyParam detail helper'+cmp.get("v.familyParam"));
    action.setCallback(this, $A.getCallback(function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
                var resultData = JSON.parse(response.getReturnValue());
                console.log(resultData);
        cmp.set('v.myData', resultData);
      } else if (state === "ERROR") {
        var errors = response.getError();
        console.error(errors);
      }
    }));
    $A.enqueueAction(action);
  },
    sortData: function (cmp, fieldName, sortDirection){
        var data = cmp.get("v.myData");
        var reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortBy(fieldName, reverse))
        cmp.set("v.myData", data);
    },
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
            function(x) {return x[field]};
        //checks if the two rows should switch places
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            a = key(a);
            b = key(b);
            var c = reverse * ((a > b) - (b > a));
            return a, b, c;
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