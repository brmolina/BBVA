({
  getTableData: function (cmp, event, helper) {
    console.log('>>>>> cmp : ' + cmp)
    var action = cmp.get('c.getData');
      action.setParams({ tableSize: '5', gmRolVery: cmp.get('v.gmRolVery')});
    action.setCallback(this, $A.getCallback(function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var resultData = JSON.parse(response.getReturnValue());
        console.log('>>>>> resultData:');
        console.log(resultData);
        cmp.set('v.myData', resultData);
          if(resultData.length >=6) {
          cmp.set('v.numberRow', true);
          }
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
        data.sort(this.sortBy(fieldName, reverse))
        cmp.set("v.myData", data);
    },
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
        function(x) {return x[field]};
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));//NOSONAR
        }
    }
})