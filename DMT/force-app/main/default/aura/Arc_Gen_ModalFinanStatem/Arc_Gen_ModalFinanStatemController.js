({
  initEng: function(component, event, helper) {
    var isProposal = component.get('v.isProposal');
    var userCanEdit = component.get('v.userCanEdit');

    if (isProposal && !userCanEdit) {
      component.set('v.ffssErrorMsg', 'You do not have the necessary permissions to perform this action.');
      component.set('v.spinnerLoading', false);
      return;
    }
    if (component.get('v.isRAIP')) {
      component.set('v.maxRowSelection', 1);
    }
    helper.setColumns(component);
    helper.fetchFinancialStatements(component, event, helper);
  },
  updateSelectedRows: function(component, event, helper) {
    var setRows = [];
    var selectedAnchor = [];
    var anchorEEFF = component.get('v.anchorEEFF');
    selectedAnchor.push(anchorEEFF);
    component.set('v.msgTable', '');
    component.set('v.errorMsgTable', '');
    var selectedRows = event.getParam('selectedRows');
    if (component.get('v.isFinancialRAIP') && helper.isPreselected(component, selectedRows)) {
      helper.toastMessage(component, event, 'info', $A.get('$Label.c.Arc_Gen_CannotSelectFFSS'));
      if (selectedRows.length) {
        for (var i = 0; i < selectedRows.length; i++) {
          setRows.push(selectedRows[i].arce__financial_statement_id__c);
        }
      }
      setRows.push(anchorEEFF);
      component.set('v.selectedRows', setRows);
    } else if (!component.get('v.isFinancialRAIP')) {
      if (selectedRows.length > 0) {
        for (var j = 0; j < selectedRows.length; j++) {
          setRows.push(selectedRows[j].arce__financial_statement_id__c);
        }
        helper.autoOrder(component, new Set(setRows));
        component.set('v.selectedRows2', setRows);
        helper.evtSelectionFFSS(component, selectedRows);
        component.set('v.btnStmIsDisabled', false);
      } else {
        component.set('v.btnStmIsDisabled', true);
      }
    }
    if (selectedRows.length > 0 && !helper.isPreselected(component, selectedRows)) {
      for (var k = 0; k < selectedRows.length; k++) {
        setRows.push(selectedRows[k].arce__financial_statement_id__c);
      }
      helper.autoOrder(component, new Set(setRows));
      component.set('v.selectedRows2', setRows);
      helper.evtSelectionFFSS(component, selectedRows);
      component.set('v.btnStmIsDisabled', false);
      component.set('v.selectedRows', setRows);
      component.set('v.preSelectedRows', setRows);
    }
  },
  callTablesEngine: function(component, event, helper) {
    component.set('v.btnStmIsDisabled', true);
    let promise = helper.consultEngine(component, event, helper);
    return promise.then(function() {
      helper.consultFSdetails(component, event, helper);
      helper.evtUpdateBalances(component);
      component.set('v.spinnerLoading', false);
    }).catch(function() {
      component.set('v.spinnerLoading', false);
    });
  },
  handleSort: function(cmp, event, helper) {
    helper.handleSort(cmp, event);
  },
  handleSaveEdition: function(cmp, event, helper) {
    var draftValues = event.getParam('draftValues');
    helper.saveEdition(cmp, helper, draftValues);
  },
  loadMoreData: function(cmp, event, helper) {
    var spinnerLoading = cmp.get('v.spinnerLoading');
    if (!spinnerLoading && !cmp.get('v.isRTC')) {
      cmp.set('v.spinnerLoading', true);
      var currentPage = cmp.get('v.currentPage');
      var nextPage = currentPage + 1;
      cmp.set('v.currentPage', nextPage);
      helper.fetchFinancialStatements(cmp, event, helper);
    }
  }
});