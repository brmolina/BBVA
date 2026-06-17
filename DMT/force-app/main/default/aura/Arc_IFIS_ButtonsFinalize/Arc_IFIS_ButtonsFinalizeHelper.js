({
  getRatingData: function(component, event, helper) {
    const methodName = 'getRatingData';
    const params = { ahaId: component.get('v.ahaId') };

    helper.promise(component, methodName, params)
      .then((result) => {
        const resp = result.data;
        if (result.success) {
          component.set('v.ratingId', resp.ratingId);

          if (resp.recalculateRating === 'Show') {
            component.set('v.showModal', true);
          } else {
            helper.closeModal(component);
            helper.warning(resp.recalculateRating, { duration: 5000 });
          }

          const currentUserId = $A.get('$SObjectType.CurrentUser.Id');
          component.set('v.selectedUserId', currentUserId);
          component.set('v.isLoading', false);
        } else {
          helper.error(result.message, { duration: 5000 });
        }
      })
      .catch((errorMessage) => {
        helper.error(errorMessage, { duration: 5000 });
      });
  },

  finalizeRating: function(component, event, helper) {
    const selectedAha = component.get('v.ahaId');
    const paramsMap = {
      ahaId: selectedAha,
      ratingId: component.get('v.ratingId'),
      validatedById: component.get('v.selectedUserId'),
      description: component.get('v.valDescription'),
      ambit: component.get('v.selectedAmbitId')
    };
    const methodName = 'callRatingValidation';
    const params = { valDataJson: JSON.stringify(paramsMap) };

    helper.promise(component, methodName, params)
      .then((result) => {
        if (result.success) {
          helper.success($A.get('{!$Label.arce.Arc_IFIS_BtnFinalize_Success}'), { duration: 2500, title: 'Success' });
          helper.refreshTab(component);
          helper.closeModal(component);
        } else {
          helper.error(result.serviceMessage, { duration: 5000 });
        }
      })
      .catch((errorMessage) => {
        helper.error(errorMessage, { duration: 5000 });
      })
      .finally(() => {
        component.set('v.isLoading', false);
        component.set('v.showModal', false);
      });
  },

  closeModal: function(component) {
    component.set('v.showModal', false);
    component.destroy();
  },

  refreshTab: function() {
    window.setTimeout($A.getCallback(function() {
      window.location.reload();
    }), 2500);
  }
});