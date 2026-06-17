({
  doInit: function (component, event, helper) {
    helper.fetchMembers(component, helper);
  },
  navigateRecord: function (component, event, helper) {
    var target = event.target.id;
    var navEvt = $A.get("e.force:navigateToSObject");
    navEvt.setParams({
      "recordId": target
    });
    navEvt.fire();
  },
})