({
  doInit: function(cmp, event, helper) {
    helper.doInit(cmp, event, helper);
  },

  waiting: function(cmp) {
    cmp.set('v.waiting', true);
  },

  toggleGroup: function(cmp, event, helper) {
    helper.toggleGroup(cmp, event, helper);
  },

  evaluateToggleGroup: function(cmp, event, helper) {
    helper.flatToggleGroup(cmp, event, helper);
  },

  handleCancel: function(cmp, event, helper) {
    helper.destroyCmp(cmp, event, helper);
  },

  handleContinue: function(cmp, event, helper) {
    helper.handleContinue(cmp, event, helper);
  },

  doneWaiting: function(cmp) {
    cmp.set('v.waiting', false);
  },

  dismissWarning: function(cmp, event, helper) {
    cmp.set('v.showWarning', false);
  },

  dismissNotChecked: function(cmp, event, helper) {
    cmp.set('v.showNotChecked', false);
  }
})