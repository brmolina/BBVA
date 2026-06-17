({//eslint-disable-line
  normalizeBoolean: function(value) {
    return value === true || String(value).toLowerCase() === 'true';
  },

  doInit: function(component, event, helper) {
    let actionCtrl = component.get('c.getJSONRecordType');
    actionCtrl.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS' && response.getReturnValue() !== null && response.getReturnValue() !== undefined) {
        if (response.getReturnValue() === 'emptyRecordType') {
          component.set('v.showError', true);
          component.set('v.showModal', true);
        } else if (response.getReturnValue().includes('oneRecordType')) {
          let staticLabelNew = $A.get('$Label.c.NClient_headerText_New');
          let isAdditional = helper.normalizeBoolean(response.getReturnValue().split('||')[2]);
          $A.createComponent('c:NONC_createNonClient', {
            'headerText': (staticLabelNew + ' ' + response.getReturnValue().split('||')[1]),
            'isAdditionalRT': isAdditional
          },
          function(modalComponent, status, errorMessage) {
            if (status === 'SUCCESS') {
              var body = component.find('createFormDuplicate').get('v.body');
              body.push(modalComponent);
              component.find('createFormDuplicate').set('v.body', body);
            } else if (status === 'INCOMPLETE') {
              console.log('Server issue or client is offline.');
            } else if (status === 'ERROR') {
              console.log('error');
            }
          }
          );
        } else {
          var respuesta = JSON.parse(response.getReturnValue());
          component.set('v.options', respuesta);

          // component.set('v.value', respuesta[0].value);
          component.set('v.isAdditional', helper.normalizeBoolean(respuesta[0].value));
          component.set('v.recordtypeName', respuesta[0].label);
          component.set('v.showModal', true);
        }
      } else if (response.getState() === 'ERROR') {
        console.log(actionCtrl.getError());
      }
    });
    $A.enqueueAction(actionCtrl);
  },
  handleChange: function(component, event) {
    let selectedValue = event.getParam('value');
    let isAdditional = selectedValue === true || String(selectedValue).toLowerCase() === 'true';
    component.set('v.isAdditional', isAdditional);
    let options = component.get('v.options') || [];
    if (options.length >= 2) {
      let firstIsAdditional = isAdditional === (options[0].value === true || String(options[0].value).toLowerCase() === 'true');
      component.set('v.recordtypeName', firstIsAdditional ? options[0].label : options[1].label);
    }
  },
  handleNext: function(component, event, helper) {
    console.log('PASAR POR AQUI NEXT ');
    let staticLabelNew = $A.get('$Label.c.NClient_headerText_New');
    $A.createComponent('c:NONC_createNonClient', {
      'headerText': staticLabelNew + ' ' + component.get('v.recordtypeName'),
      'isAdditionalRT': component.get('v.isAdditional')
    },
    function(modalComponent, status, errorMessage) {
      if (status === 'SUCCESS') {
        component.set('v.showModal', false);
        var body = component.find('createFormDuplicate').get('v.body');
        body.push(modalComponent);
        component.find('createFormDuplicate').set('v.body', body);
      } else if (status === 'INCOMPLETE') {
        console.log('Server issue or client is offline.');
      } else if (status === 'ERROR') {
        console.log('error');
      }
    }
    );
  },
  closeModal: function(component, event, helper) {
    let isOnAccount = component.get('v.isOnAccount');
    if (component.get('v.isOnDesktop') !== 'DESKTOP') {
      var homeEvent = $A.get('e.force:navigateToObjectHome');
      homeEvent.setParams({
        'scope': 'Account'
      });
      homeEvent.fire();
    }
    if (isOnAccount) {
      $A.get('e.force:navigateToURL').setParams({ 'url': '/lightning/o/Account/home' }).fire();
    }
    component.destroy();
  },
  handleComponentEvent: function(component, event, helper) {
    var message = event.getParam('message');
    component.set('v.messageFromEvent', message);
    var numEventsHandled = parseInt(component.get('v.numEvents')) + 1;
    component.set('v.numEvents', numEventsHandled);
    if (message === 'Close component') {
      component.destroy();
    }
  }
});