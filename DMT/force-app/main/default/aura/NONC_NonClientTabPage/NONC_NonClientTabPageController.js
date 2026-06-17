({//eslint-disable-line
  doInit: function(component, event, helper) {
    helper.getListViewName(component, event, helper);
  },
  create: function(component, event, helper) {
    helper.createNonClient(component, event, helper);
  }
});