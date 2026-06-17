({
  doInit: function(component, event, helper) {
    let promise = helper.createGroupRiskTable(component, helper);
    promise.then(
      function(resolve) {
        helper.doComponent(component);
      }
    ).catch(
      function(error) {
        component.set('v.spinner', 'false');
      }
    );
  }
});