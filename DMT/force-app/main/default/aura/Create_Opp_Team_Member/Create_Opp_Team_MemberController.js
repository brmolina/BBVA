({
  doInit: function(component,event,helper){
    helper.getRTName(component,event,helper);
  },
  onChangeTeamRole: function(component, event, helper) {
    helper.checkTeamRole(component, component.find("teamroleField").get("v.value"));
    helper.setScope(component, component.find("teamroleField").get("v.value"));
  },
  cancelForm: function(component, event) {
      var dismissActionPanel = $A.get('e.force:closeQuickAction');
      dismissActionPanel.fire();
  },
  handleComponentEvent : function(component,event,helper) {
    helper.helperComponentEvent(component, event);
  },
  saveForm: function(component, event, helper) {
    helper.newOppTeamMember(component, event);
    var showErrors = component.get("v.showError");
      if(showErrors === false){
        var actionClicked = event.getSource().getLocalId();
        var navigate = component.get("v.navigateFlow");
        navigate(actionClicked);
    }
  }
});