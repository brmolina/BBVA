({
  doInit: function(component, event, helper) {
    helper.callPersistOverlay(component)
      .then(function(result) {
        return helper.callOverlayRating(component, event);
      })
      .then(function(result) {
        helper.ratingProcessOK(component);
      })
      .catch(function(err) {
        helper.cancelAction(component);
      });
  }
});