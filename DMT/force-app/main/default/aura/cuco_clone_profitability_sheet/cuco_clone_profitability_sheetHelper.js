/* eslint-disable no-unused-expressions */
({
    doInit: function(cmp, event, helper) {
      helper.waiting(cmp);
      helper.doneWaiting(cmp);
    },
    waiting: function(cmp) {
      cmp.set('v.waiting', true);
    },
    doneWaiting: function(cmp) {
      cmp.set('v.waiting', false);
    },
    empty: function(string) {
      return (string === null || string === '' || string === undefined);
    },
    showToast: function(type, title, duration, message) {
      var toastEvent = $A.get('e.force:showToast');
      toastEvent.setParams({
        title: title,
        message: message,
        duration: 5000,
        key: 'info_alt',
        type: type,
        mode: 'dismissible'
      });
      toastEvent.fire();
    },
    closePanel: function() {
      $A.get("e.force:closeQuickAction").fire();
    }
  });