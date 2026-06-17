({
    saveForm: function(component, event, helper) {
      console.log('::::: DENTRO DE SAVEFORM');
      helper.newPitch(component, event);
      var showErrors = component.get('v.showError');
      console.log('::::: showErrors: ', showErrors);
      if(showErrors === false){
        var actionClicked = event.getSource().getLocalId();
        var navigate = component.get('v.navigateFlow');
        	navigate(actionClicked);
        }
    },
      cancelar : function(component, event, helper) {
      console.log('::::: DENTRO DE CANCELAR');
        $A.get('e.force:closeQuickAction').fire();
      }
})