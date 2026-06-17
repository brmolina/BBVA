({
  doInit: function(component, event, helper) {
    component.set('v.spinner', 'true');
    helper.getInfoAnalysis(component, event, helper)
      .then(function(resolveInfo) {
        helper.validationsBeforeCall(component, event, helper)
          .then(function(resolve) {
            helper.invokeServices(component, helper);
          })
          .catch(function(error) {
            helper.cancelAction(component);
          });
      })
      .catch(function(error) {
        helper.cancelAction(component);
      });
  }
});