({
    getTableData : function(component) {
        var action = component.get('c.getTableData');
        action.setParams({
            'accountPlanId': component.get('v.recordId')
        });
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var resultData = JSON.parse(response.getReturnValue());
                console.log('::::::::RESULTDATA? de la tabla' , resultData);
                component.set('v.myData', resultData);
            } else if (state === "ERROR") {
                var errors = response.getError();
                console.error(errors);
            }
        }));
        $A.enqueueAction(action);
    },
    sortData: function (component, fieldName, sortDirection){
        var data = component.get("v.myData");
        var reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortBy(fieldName, reverse))
        component.set("v.myData", data);
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
    }
    
})