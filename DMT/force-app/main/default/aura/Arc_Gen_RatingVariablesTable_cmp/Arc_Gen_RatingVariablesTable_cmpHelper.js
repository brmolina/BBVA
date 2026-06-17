({
  getData: function(cmp, ratingId) {
    var action = cmp.get('c.getDataTable');
    action.setParams({
      ratingId: ratingId
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = response.getReturnValue();
        if (resp.status === 'Success') {
          cmp.set('v.success', 'yes');
          var temojson = JSON.parse(JSON.stringify(resp.tableJson).split('items').join('_children'));
          cmp.set('v.gridData', JSON.parse(temojson));
        } else {
          cmp.set('v.success', 'no');
          cmp.set('v.message', resp.errorMessage);
        }
      }
    });
    $A.enqueueAction(action);
  }
});