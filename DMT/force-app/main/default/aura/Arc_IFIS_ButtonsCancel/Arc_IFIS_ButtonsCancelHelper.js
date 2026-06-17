({
  fetchDiscardReasons: function(component) {
    const methodName = 'fetchDiscardReasons';
    const params = {};

    this.promise(component, methodName, params)
      .then((result) => {
        component.set('v.reasonList', result);
      })
      .catch((errorMessage) => {
        this.error(errorMessage, { duration: 5000 });
      })
      .finally(() => {
        component.set('v.isLoading', false);
      });
  },

  setupReasonLabel: function(component, event, helper) {
    const list = component.get('v.reasonList');
    const currentLabel =  list.filter(function(option) {
      return option.value === event.getParam('value');
    });
    component.set('v.reasonLabel', currentLabel[0].label);
  },

  cancelRating: function(component, event, helper) {
    const methodName = 'cancelRating';
    const params = {
      ahaId: component.get('v.ahaId'),
      reasonValue: component.get('v.reasonValue'),
      reasonLabel: component.get('v.reasonLabel'),
      reasonDesc: component.find('reasonDesc').get('v.value')
    };

    helper.promise(component, methodName, params)
      .then((result) => {
        const resp = JSON.parse(result);
        if (resp.status === 'true') {
          helper.closeModal(component);
          helper.refreshTab(component);
        } else {
          helper.error(resp.message, { duration: 5000 });
        }
      })
      .catch((errorMessage) => {
        helper.error(errorMessage, { duration: 5000 });
      })
      .finally(() => {
        component.set('v.isLoading', false);
      });
  },

  closeModal: function(component) {
    component.set('v.showModal', false);
    component.destroy();
  },

  refreshTab: function() {
    window.location.reload();
  }
});