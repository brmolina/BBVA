({
  doInit: function(cmp, event, helper) {
    helper.doInit(cmp, event, helper);
  },

  waiting: function(cmp) {
    cmp.set('v.waiting', true);
  },

  handleCancel: function(cmp, event, helper) {
    helper.destroyCmp(cmp, event, helper);
  },

  doneWaiting: function(cmp) {
    cmp.set('v.waiting', false);
  }
})