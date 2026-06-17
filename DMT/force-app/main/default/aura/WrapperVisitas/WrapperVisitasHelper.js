({
  launchSyncronization: function(cmp, evt, helper) {
    let notifications = evt.getParam('notifications');

    let action = cmp.get('c.sendToGoogle');
    action.setParams({
      visitId: cmp.get('v.recordId'),
      notifications: notifications
    });
    action.setCallback(this, function(response) {

    });
    $A.enqueueAction(action);
  }
});