({
  doInit: function(component, event, helper) {
    let promise = helper.getUrlConfig(component, helper);
    promise.then(function() {
      component.set('v.warningMsg', $A.get('{!$Label.c.Arc_Gen_RAIP_GBL_AdjCorporateWarning}'));
      component.set('v.showbutton', true);
      component.set('v.spinnerStatus', false);
    })
      .catch(function(errDoInit) {
        helper.setError(component, errDoInit);
      });
  },
  closeModal: function(component) {
    component.destroy();
  },
  handleYes: function(component, event, helper) {
    component.set('v.warningMsg', $A.get('{!$Label.c.Arc_Gen_RAIP_GBL_redirect_warning}'));
    component.set('v.showbutton', false);
    component.set('v.spinnerStatus', true);
    let promise = helper.handleRedirect(component, helper);
    promise.then(function() {
      var redirectWin = window.open(component.get('v.orgURL'), '_blank');
      setTimeout(function() {
        redirectWin.close();
        var form = document.getElementById('Formulario');
        form.submit();
        component.destroy();
        $A.get('e.force:refreshView').fire();
      }, 5000);
    })
      .catch(function(errHandle) {
        helper.setError(component, errHandle);
      });
  },
  handleNo: function(component) {
    component.destroy();
  },
});