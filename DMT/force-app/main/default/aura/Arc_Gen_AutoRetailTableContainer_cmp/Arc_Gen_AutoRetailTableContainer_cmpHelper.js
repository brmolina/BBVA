({
  setTableTitle: function(component) {
    switch (component.get('v.tableType')) {
      case '1':
        component.set('v.tableTitle', $A.get('$Label.c.Lc_arce_autoRetailTable_NewsTable'));
        break;
      case '2':
        component.set('v.tableTitle', $A.get('$Label.c.Lc_arce_autoRetailTable_SemiNewsTable'));
        break;
      default:
        break;
    }
  },
  setYearOptions: function(component) {
    var options = [];
    var today = new Date();
    var currentYear = today.getFullYear();
    for (let i = currentYear; i >= currentYear - 6; i--) {
      var element = { value: i, label: String(i) };
      options.push(element);
    }

    component.set('v.options', options);
  },
  toastMes: function(component, event, messageType, messageInfo) {
    var toastEvent = $A.get('e.force:showToast');
    toastEvent.setParams({
      'type': messageType,
      'title': '',
      'message': messageType === 'SUCCESS' ? $A.get('$Label.c.Arc_Gen_Record_Update_Success') : messageInfo
    });
    toastEvent.fire();
  },
  manageButtonVisibility: function(component, selectedYear) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var currentYear = parseInt(selectedYear);
      if (currentYear !== 0) {
        var previousYear = selectedYear -  1;
        component.set('v.year1', previousYear.toString());
        component.set('v.year2', currentYear.toString());
        resolve();
      } else {
        reject();
      }
    }));
  },
  getPreviouslySelectedYear: function(component, event) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var action = component.get('c.getPreviouslySelectedYear');
      action.setParams({
        'accHasAnalysisId': component.get('v.recordId')
      });
      action.setCallback(this, function(response) {
        if (response.getState() === 'SUCCESS') {
          var results = response.getReturnValue();
          if (results.hasYearSelected === 'true') {
            component.set('v.year2', results.year);
            var year1 = parseInt(results.year, 10) - 1;
            component.set('v.year1', year1.toString());
            component.set('v.permToEdit', results.permissionToEdit);
            var analysisInPreparation = results.arceStage === '1';
            component.set('v.insert', analysisInPreparation);
            component.set('v.edit', analysisInPreparation);
            component.set('v.delete', analysisInPreparation);
            resolve(results.year);
          } else {
            reject();
          }
        } else {
          reject(response.getError()[0].message);
        }
      });
      $A.enqueueAction(action);
    }));
  }
});