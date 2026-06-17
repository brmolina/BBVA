({
  fetchMembers: function (component, helper) {
    var action = component.get('c.gtMembers');
    action.setCallback(this, function (response) {
      var state = response.getState();
      console.log(state);
      if (state === 'SUCCESS') {
        component.set('v.members', JSON.parse(response.getReturnValue()));
        component.set('v.sizeMembers', JSON.parse(response.getReturnValue()).length);
      }
    });
    $A.enqueueAction(action);
  }
})