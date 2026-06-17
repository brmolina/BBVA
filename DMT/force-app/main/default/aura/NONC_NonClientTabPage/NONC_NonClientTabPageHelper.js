({//eslint-disable-line
  createNonClient: function(component, event, helper) {
    $A.createComponent('c:NONC_selectorRTNonClient', {'headerText': $A.get('$Label.c.NClient_lbl_NewProspect')},
      function(modalComponent, status, errorMessage) {
        if (status === 'SUCCESS') {
          var body = component.find('showChildModal').get('v.body');
          body.push(modalComponent);
          component.find('showChildModal').set('v.body', body);
        } else if (status === 'INCOMPLETE') {
          console.log('Server issue or client is offline.');
        } else if (status === 'ERROR') {
          console.log('error');
        }
      }
    );
  },
  getListViewName: function(component, event, helper) {
    let actionCtrl = component.get('c.getApiName');
    actionCtrl.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS' && response.getReturnValue() !== null && response.getReturnValue() !== undefined && response.getReturnValue() !== '') {
        component.set('v.listViewName', response.getReturnValue());
        component.set('v.isVisible', true);
      } else {
        component.set('v.isVisible', false);
        var toastEvent = $A.get('e.force:showToast');
        toastEvent.setParams({
          title: '',
          type: 'error',
          mode: 'dismissible',
          message: $A.get('$Label.c.NClient_lbl_NoListView')
        });
        toastEvent.fire();
      }
    });
    $A.enqueueAction(actionCtrl);
  },
});