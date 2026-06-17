({
  doInit: function(component, event, helper) {
    helper.getInfoAnalysis(component, event, helper)
      .then(function() {
        helper.executeService(component, helper)
          .then(function() {
            component.set('v.message', $A.get('{!$Label.c.Lc_arce_successAndCloseWindow}'));
            component.set('v.success', 'yes');
            helper.refreshTab(component);
            component.set('v.spinner', 'false');
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