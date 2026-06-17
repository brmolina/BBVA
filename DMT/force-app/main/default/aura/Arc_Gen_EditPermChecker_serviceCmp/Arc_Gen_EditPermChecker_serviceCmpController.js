({
  checkEditPermission: function(cmp, evt, helper) {
    const ahaId = evt.getParam('arguments').ahaId;
    return new Promise($A.getCallback(function(resolve, reject) {
      const checkAction = cmp.get('c.getUserHasPermissionToEdit');
      checkAction.setParams({
        recordId: ahaId
      });
      checkAction.setCallback(this, function(response) {
        const state = response.getState();
        if (state === 'SUCCESS') {
          const hasEditPerm = response.getReturnValue();

          if (hasEditPerm) {
            resolve();
          } else {
            reject($A.get('$Label.c.Arc_Gen_Generic_NotAllowed'));
          }
        } else {
          reject($A.get('$Label.c.Arc_Gen_Toas_Unknown'));
        }
      });

      $A.enqueueAction(checkAction);
    }));
  }
});