({
  cancelForm: function(component, event) {
      var dismissActionPanel = $A.get('e.force:closeQuickAction');
      dismissActionPanel.fire();
  },

  saveForm: function(component, event, helper) {
    helper.newBBVAParticipant(component, event);
    var showErrors = component.get("v.showError");
      if(showErrors === false){
        var actionClicked = event.getSource().getLocalId();
        var navigate = component.get("v.navigateFlow");
        navigate(actionClicked);
    }
  }
});