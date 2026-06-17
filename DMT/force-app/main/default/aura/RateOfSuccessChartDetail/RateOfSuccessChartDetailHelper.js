({
  getTableData : function(cmp) {
    var action = cmp.get('c.getOppProducts');
        action.setParams({ clientId : cmp.get("v.recordId") });
    action.setCallback(this, $A.getCallback(function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
                var resultData = JSON.parse(response.getReturnValue());
        cmp.set('v.myData', resultData);
      } else if (state === "ERROR") {
        var errors = response.getError();
        console.error(errors);
      }
    }));
    $A.enqueueAction(action);
  },
    sortData: function (cmp, fieldName, sortDirection) {
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
    navigateGoBackBefore : function(cmp, event, helper) {
        let filialOrGroup = 'c:Salesforce1QuickAction';
        if(cmp.get('v.filial')) {
            filialOrGroup = 'c:Salesforce1QuickActionFilial';
        }
        var evt = $A.get('e.force:navigateToComponent');
        evt.setParams({
            componentDef : filialOrGroup,
            componentAttributes: {
                recordId: cmp.get('v.recordId')
            }
        });
        evt.fire();
    }
})