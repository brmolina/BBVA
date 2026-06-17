({
  calculateLeverage: function(component, analysisId) {
    var action = component.get('c.setupLeverage');
    action.setParams({
      analysisId: analysisId
    });
    action.setCallback(this, function(response) {
      var resp = response.getReturnValue();
      var state = response.getState();
      if (state === 'SUCCESS') {
        if (resp.status === 'true') {
          component.set('v.leveragedIndBefore', resp.leveragedVariables[0]);
          component.set('v.leveragedTypeBefore', resp.leveragedVariables[1]);
          component.set('v.leveragedIndAfter', resp.leveragedVariables[2]);
          component.set('v.leveragedTypeAfter', resp.leveragedVariables[3]);
          component.set('v.message', $A.get('{!$Label.c.Lc_arce_successAndCloseWindow}'));
          component.set('v.success', 'yes');
          this.refreshLeverage(component);
        } else {
          component.set('v.message', resp.message);
          component.set('v.success', 'no');
        }
      } else {
        component.set('v.success', 'no');
        var mensaje = resp.errorMessage;
        var resultsToast = $A.get('e.force:showToast');
        resultsToast.setParams({
          'title': $A.get('{!$Label.c.Lc_arce_newAnalysisError}'),
          'type': 'error',
          'message': mensaje,
          'duration': '8000'
        });
        resultsToast.fire();
        $A.get('e.force:closeQuickAction').fire();
      }
    });
    $A.enqueueAction(action);
  },
  refreshLeverage: function(component) {
    var tabRefresh = $A.get('e.dyfr:SaveObject_evt');
    tabRefresh.setParams({
      'recordId': component.get('v.recordId')
    });
    tabRefresh.fire();
  }
});