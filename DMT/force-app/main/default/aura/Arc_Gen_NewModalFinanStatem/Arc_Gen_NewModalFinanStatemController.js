({
  initEng: function(component, event, helper) {
    component.set('v.spinnerLoading', true);
    if (component.get('v.fromButton')) {
      helper.getVariablesButton(component, event, helper);
    } else {
      component.set('v.cssClass', '');
      component.set('v.cssClassbackdrop', '');
      component.set('v.cssClassModal', '');
      helper.fetchFinancialStatements(component, event, helper);
      helper.isRatingAvaiable(component);
      helper.checkNplStatus(component, event, helper);
    }
    if (component.get('v.ratingSys') === 'IFIS') {
      component.set('v.maxRowSelection', 3);
    }
    helper.setColumns(component);
    helper.enableNextButton(component, false);
  },
  updateSelectedRows: function(component, event, helper) {
    helper.enableNextButton(component, false);
    component.set('v.msgTable', '');
    component.set('v.errorMsgTable', '');
    var selectedRows = event.getParam('selectedRows');
    if (component.get('v.isFinancialRAIP') && helper.isPreselected(component, selectedRows)) {
      helper.toastMessage(component, event, 'info', $A.get('$Label.c.Arc_Gen_CannotSelectFFSS'));
      component.set('v.selectedRows', component.get('v.preSelectedRows'));
    } else {
      var setRows = [];
      if (selectedRows.length > 0) {
        var isNotAnyApply = false;

        //Clear buttons and data
        component.set('v.nextDisabled', true);
        component.set('v.variantRating', 'neutral');
        component.set('v.variantPreRating', 'neutral');
        component.set('v.ratingType', '');
        for (var i = 0; i < selectedRows.length; i++) {
          setRows.push(selectedRows[i].arce__financial_statement_id__c);
          if (selectedRows[i].arce__ffss_apply_for_rating_type__c === 'No' || selectedRows[i].arce__ffss_apply_for_rating_type__c === '2') {
            isNotAnyApply = true;
          }
        }

        helper.updateRatingState(component, isNotAnyApply);

        helper.autoOrder(component, new Set(setRows));
        component.set('v.selectedRows2', setRows);

      }
    }

  },
  handleSort: function(cmp, event, helper) {
    helper.handleSort(cmp, event);
  },
  handleClickRating: function(cmp, event, helper) {
    helper.handleClickRating(cmp, event, helper);
  },
  handleSaveEdition: function(cmp, event, helper) {
    var draftValues = event.getParam('draftValues');
    helper.saveEdition(cmp, helper, draftValues);
  },
  loadMoreData: function(cmp, event, helper) {
    cmp.set('v.spinnerLoading', true);
    var currentPage = cmp.get('v.currentPage');
    var nextPage = currentPage + 1;
    cmp.set('v.currentPage', nextPage);
    cmp.set('v.variantPreRating', 'neutral');
    cmp.set('v.ratingType', '');
    cmp.set('v.nextDisabled', true);
    helper.enableNextButton(cmp, false);
    helper.fetchFinancialStatements(cmp, event, helper);
  },
  Cancel: function(component, event, helper) {
    component.set('v.show', false);
  },
  handleNext: function(component, event, helper) {
    helper.consultEngine(component, event, helper);
  }
});