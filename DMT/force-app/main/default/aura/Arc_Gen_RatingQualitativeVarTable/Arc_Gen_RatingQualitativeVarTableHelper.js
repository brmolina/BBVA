({
  getData: function(cmp, ratingId) {
    var action = cmp.get('c.getQualitativeTable');
    action.setParams({
      ratingId: ratingId
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = response.getReturnValue();
        if (resp.status === 'Success') {
          var tableData = response.getReturnValue();
          var tempjson = JSON.parse(JSON.stringify(tableData.tableJson).split('items').join('_children'));
          cmp.set('v.data', JSON.parse(tempjson));
        }
      }
    });
    $A.enqueueAction(action);
  }
});