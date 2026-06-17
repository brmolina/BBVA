({
  init: function(component, event, helper) {
    helper.hinit(component, event);
  },
  handleRowAction: function(component, event, helper) {
    var action = event.getParam('action');
    switch (action.name) {
      case 'edit':
        helper.edit(component, event);
        break;
      case 'insert':
        helper.insert(component, event);
        break;
      case 'delete':
        helper.delete(component, event);
        break;
    }
  },
  refreshTable: function(component, event, helper) {
    helper.hinit(component, event);
  },
  handleRefreshEvt: function(component, event, helper) {
    component.set('v.spinnerStatus', true);
    var recordId = component.get('v.recordId');
    if (event.getParam('table') === 'PositionTable' && component.get('v.recordId') === event.getParam('recordId')) {
      helper.hinit(component, event);
      if (component.get('v.automaticFunction') === 'true') {
        helper.handleServiceRefresh(component).then(function() {
          return helper.handleReload(component);
        }).then(function() {
          helper.toastMes(component, event, 'SUCCESS', 'SUCCESS');
          var tabRefresh = $A.get('e.dyfr:SaveObject_evt');
          tabRefresh.setParams({
            'recordId': recordId
          });
          tabRefresh.fire();
        }).catch(function() {
          helper.toastMes(component, event, 'error', $A.get('$Label.c.Lc_arce_NewARCE_UnexpectedError'));
        });
      }
    }
  }
});