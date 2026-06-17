({
  handleSearch: function(component, event, helper) {
    component.set('v.isVisibleOptions', false);
    component.set('v.isVisibleButton', false);
    component.set('v.spinner', true);
    var queryTerm = component.find('enter-search').get('v.value');
    if (queryTerm.length > 3) {
      var actionCall = component.get('c.searchUser');
      actionCall.setParams({
        inputTerm: queryTerm
      });
      actionCall.setCallback(this, function(response) {
        var state = response.getState();
        component.set('v.spinner', false);
        if (state === 'SUCCESS') {
          var resp = response.getReturnValue();
          if (resp.length > 0) {
            component.set('v.isVisibleOptions', true);
            component.set('v.ltsUsers', resp);
          }
        } else {
          helper.showToast('error', JSON.stringify(response.error));
        }
      });
      $A.enqueueAction(actionCall);
    }
  },
  itemSelected: function(component, event, helper) {
    component.set('v.isVisibleOptions', false);
    var seleccionado = event.getParam('name');
    component.set('v.idUserSelected', seleccionado.split('_')[0]);
    component.set('v.userSelected', seleccionado.split('_')[1]);
    component.set('v.isVisibleButton', true);
  },
  handleClick: function(component, event, helper) {
    var inputAttributes = component.get('v.inputAttributes');
    helper.setValidation(component, 'spinner', 'si');
    var actionCall = component.get('c.toAssign');
    actionCall.setParams({
      userId: component.get('v.idUserSelected'),
      recordId: inputAttributes.recordId
    });
    actionCall.setCallback(this, function(response) {
      var state = response.getState();
      helper.setValidation(component, 'spinner', 'no');
      helper.setValidation(component, 'response', 'si');
      if (state === 'SUCCESS') {
        var resp = response.getReturnValue();
        helper.setValidation(component, 'message', resp);
        helper.setValidation(component, 'icon', 'utility:success');
        helper.setValidation(component, 'style', 'some-success');
        window.setTimeout($A.getCallback(function() {
          helper.setValidation(component, 'response', 'no');
        }), 5000);
      } else {
        helper.setValidation(component, 'message', response.getError()[0].message);
        helper.setValidation(component, 'icon', 'utility:warning');
        helper.setValidation(component, 'style', 'some-warning');
      }
    });
    $A.enqueueAction(actionCall);
  },
  closeModel: function(component, event, helper) {
    component.destroy();
  }
});