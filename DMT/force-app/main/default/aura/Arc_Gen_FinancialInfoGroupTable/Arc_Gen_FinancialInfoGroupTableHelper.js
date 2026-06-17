({
  getTableData: function(component, event, helper) {
    let editPerm = component.get('v.edit');
    if (editPerm === 'true') {
      component.set('v.buttonEnabled', true);
    }
    var action = component.get('c.getTableData');
    action.setParams({
      'recordId': component.get('v.recordId')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = response.getReturnValue();
        if (resp.tableFinValid.finInfoRow.length === 0) {
          component.set('v.showValidTable', false);
        } else {
          component.set('v.showValidTable', true);
          component.set('v.columns', resp.tableFinValid.columns);
          component.set('v.row', resp.tableFinValid.finInfoRow);
          component.set('v.unitsVal', resp.tableFinValid.finInfoRow[0].unitsVal);
          component.set('v.currencyVal', resp.tableFinValid.finInfoRow[0].currencyVal);
        }
        if (resp.tablePrevYear.finInfoRow.length === 0) {
          component.set('v.showPrevTable', false);
        } else {
          component.set('v.columnsYear', resp.tablePrevYear.columns);
          component.set('v.showPrevTable', true);
          component.set('v.rowYear', resp.tablePrevYear.finInfoRow);
          component.set('v.unitsVal', resp.tablePrevYear.finInfoRow[0].unitsVal);
          component.set('v.currencyVal', resp.tablePrevYear.finInfoRow[0].currencyVal);
        }

        component.set('v.tablesTitle', resp.tablesTitle);
      } else {
        helper.showToast('error', $A.get('{!$Label.c.Lc_arce_NewARCE_UnexpectedError}'));
      }
    });
    $A.enqueueAction(action);
  },
  showToast: function(type, message) {
    const toastEvent = $A.get('e.force:showToast');
    toastEvent.setParams({
      'title': '',
      'message': message,
      'type': type
    });
    toastEvent.fire();
  }
});