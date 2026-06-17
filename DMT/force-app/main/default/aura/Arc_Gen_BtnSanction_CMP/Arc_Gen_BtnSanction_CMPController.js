({
  init: function(cmp, evt, helper) {
    cmp.set('v.today', new Date().toISOString().substring(0, 10));
    helper.getArceData(cmp, evt, helper);
    let promise = helper.initializeComponent(cmp, evt, helper);
    promise.then(function() {
      cmp.set('v.spinnerStatus', false);
    });
  },
  handleChangeActions: function(cmp, evt, helper) {
    var valueAction = evt.getParam('value');
    cmp.set('v.selectedAction', valueAction);
    if (valueAction === '4' || valueAction === '6') {
      cmp.set('v.lstAmbitVisibility', true);
    } else {
      cmp.set('v.lstAmbitVisibility', false);
      cmp.set('v.selectedAmbit', null);
    }
    helper.validatesave(cmp, helper);
  },
  handleChangeAmbits: function(cmp, evt, helper) {
    cmp.set('v.selectedAmbit', evt.getParam('value'));
    helper.validatesave(cmp, helper);
  },
  handleSearch: function(cmp, evt, helper) {
    cmp.set('v.isVisibleOptions', false);
    var queryTerm = cmp.find('enter-search').get('v.value');
    if (queryTerm.length > 4) {
      cmp.set('v.spinner', true);
      var actionCall = cmp.get('c.searchUser');
      actionCall.setParams({
        inputTerm: queryTerm
      });
      actionCall.setCallback(this, function(response) {
        var state = response.getState();
        cmp.set('v.spinner', false);
        if (state === 'SUCCESS') {
          var resp = response.getReturnValue();
          if (resp.length > 0) {
            cmp.set('v.isVisibleOptions', true);
            cmp.set('v.ltsUsers', resp);
          }
        } else {
          helper.showToast('error searching ', JSON.stringify(response.error));
        }
      });
      $A.enqueueAction(actionCall);
    } else if (!queryTerm) {
      cmp.set('v.idUserSelected', '');
      cmp.set('v.userSelected', '');
      cmp.set('v.spinner', false);
      cmp.set('v.isVisibleBtn', true);
    }
  },
  handleChangeFields: function(cmp, evt, helper) {
    helper.validatesave(cmp, helper);
  },
  itemSelected: function(cmp, evt, helper) {
    var seleccionado = evt.getParam('name');
    cmp.set('v.isVisibleOptions', false);
    cmp.set('v.idUserSelected', seleccionado.split('_')[0]);
    cmp.set('v.userSelected', seleccionado.split('_')[1]);
    helper.validatesave(cmp, helper);
  },
  saveSanction: function(cmp, evt, helper) {
    cmp.set('v.isVisibleBtn', true);
    cmp.set('v.spinnerStatus', true);
    helper.saveAction(cmp, evt, helper)
      .then(function() {
        return helper.callPersistences(cmp, evt, helper);
      })
      .catch(function() {
        cmp.set('v.spinnerStatus', false);
        cmp.set('v.error', true);
        cmp.set('v.errorMessage', $A.get('$Label.c.Arc_Gen_ServicePersistenceError'));
      });
  },
  cancelAction: function(cmp, evt, helper) {
    helper.cancelAction(cmp);
  },
  closeError: function(cmp, evt, helper) {
    cmp.set('v.error', false);
  }
});