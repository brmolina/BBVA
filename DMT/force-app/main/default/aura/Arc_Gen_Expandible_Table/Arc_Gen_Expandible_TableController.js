({
  init: function(component, event, helper) {
    helper.checkInSanction(component, event).then(function() {
      helper.getTypeOfAnalysis(component, event);
      helper.getTableData(component, event);
      helper.getHeaderDate(component, event);
    });
  },
  handleRowAction: function(component, event, helper) {
    var action = event.getParam('action');
    switch (action.name) {
      case 'insert':
        helper.insertRecords(component, event);
        break;
      case 'edit':
        helper.editRecords(component, event);
        break;
      case 'show':
        helper.editRecords(component, event);
        break;
      case 'delete':
        var row = event.getParam('row');
        component.set('v.row', row);
        component.set('v.show', true);
        component.set('v.titleModal', $A.get('$Label.c.Arc_Gen_DeleteRecord'));
        component.set('v.spinner', false);
        component.set('v.delBodyModal', true);
        break;
      default:
        helper.editRecords(component, event);
        break;
    }
  },
  close: function(component, event, helper) {
    component.set('v.show', false);
  },
  accept: function(component, event, helper) {
    var row = component.get('v.row');
    component.set('v.spinner', true);
    component.set('v.delBodyModal', false);
    component.find('permChecker').checkEditPermission(component.get('v.recordId'))
      .then($A.getCallback(function() {
        let persDel = helper.persDelRecords(component, event, helper, row);
        persDel.then(function() {
          helper.deleteRecords(component, event, row);
        })
          .catch($A.getCallback(function(errorMsg) {
            component.set('v.show', false);
            helper.toastMessages('ERROR', errorMsg);
          }));
      }))
      .catch($A.getCallback(function(errorMsg) {
        component.set('v.show', false);
        helper.toastMessages('ERROR', errorMsg);
      }));
  },
  handleRefreshEvt: function(component, event, helper) {
    component.set('v.show', true);
    component.set('v.delBodyModal', false);
    component.set('v.spinner', true);
    component.set('v.titleModal', $A.get('$Label.c.Lc_arce_UpdatedPoliciesTable'));
    if (event.getParam('table') === 'PolicieTable' && component.get('v.recordId') === event.getParam('recordId')) {
      helper.handleRefreshEvt(component, event, helper)
        .then(function() {
          component.set('v.show', false);
          if (component.isValid()) {
            var tabRefresh = $A.get('e.dyfr:SaveObject_evt');
            tabRefresh.setParams({
              'recordId': component.get('v.recordId')
            });
            tabRefresh.fire();
          }
        })
        .catch(function(errorMsg) {
          component.set('v.show', false);
          helper.toastMessages('ERROR', errorMsg);
        });
    }
  },
  getProposeInfo: function(component, event, helper) {
    helper.getProposeInfo(component, event, helper);
  }
});