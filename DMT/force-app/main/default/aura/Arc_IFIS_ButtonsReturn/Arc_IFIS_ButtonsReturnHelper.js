({
  initDelegation: function(component, event, helper) {
    const methodName = 'initDelegation';
    const params = { ahaId: component.get('v.ahaId') };

    helper.promise(component, methodName, params)
      .then(function(result) {
        const resp = JSON.parse(result);
        if (resp.codStatus === 200) {
          component.set('v.delegationWrapper', resp);
          component.set('v.listAmbits', resp.lstAmbits);
          if (resp.msgInfo !== '') {
            helper.success(resp.msgInfo, { duration: 5000 });
          }
        } else if (resp.codStatus === 500) {
          helper.executeError(component, resp.msgInfo, false);
        }
      })
      .catch(function(error) {
        helper.executeError(component, error.message, true);
      })
      .finally(function() {
        component.set('v.isLoading', false);
      });
  },

  returnRating: function(component, event, helper) {
    const buttonsEvent = $A.get('e.arce:Arc_IFIS_ButtonsEvent');
    const reason = component.find('reasonInput').get('v.value');
    if (reason !== undefined && reason !== '') {
      const methodName = 'evaluateIdentification';
      const params = {
        ahaId: component.get('v.ahaId'),
        wrapper: component.get('v.delegationWrapper'),
        reason: reason
      };

      helper.promise(component, methodName, params)
        .then(function(result2) {
          const resp = JSON.parse(result2);
          if (resp.codStatus === 200) {
            if (resp.msgInfo) {
              helper.success(resp.msgInfo, { duration: 5000, title: 'Success' });
              helper.refreshComponents(buttonsEvent);
            }
            helper.closeModal(component);
          } else if (resp.codStatus === 500) {
            helper.executeError(component, resp.msgInfo, false);
          }
        })
        .catch(function(error) {
          helper.executeError(component, error.message, false);
        })
        .finally(function() {
          component.set('v.isLoading', false);
          component.set('v.disabledButtons', false);
        });

    } else {
      helper.error($A.get('{!$Label.arce.Arc_IFIS_BtnReturn_Reason_NotEmpty}'), { duration: 5000 });
      component.set('v.isLoading', false);
      component.set('v.disabledButtons', false);
    }
  },

  executeError: function(component, message, refresh) {
    if (message !== '') {
      this.error(message, {});
      this.closeModal(component);
    } else if (refresh) {
      this.refreshComponents();
    }
  },

  closeModal: function(component) {
    component.set('v.showModal', false);
    component.destroy();
  },

  refreshComponents: function(buttonsEvent) {
    buttonsEvent.fire();
    $A.get('e.force:refreshView').fire();
  }
});