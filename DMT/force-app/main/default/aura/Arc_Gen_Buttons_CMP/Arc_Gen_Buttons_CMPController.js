({
  init: function(cmp, event, helper) {
    var action = cmp.get('c.getBtnCollection');
    action.setParams({
      'recordId': cmp.get('v.recordId'),
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = response.getReturnValue();
        cmp.set('v.buttonsCollection', resp);
        cmp.set('v.view', true);
      }
    });
    $A.enqueueAction(action);
  },
  getItemEvent: function(cmp, event, helper) {
    if (event.getParam('nameEvent') === 'Arc_Gen_Carousel') {
      cmp.set('v.view', false);
      cmp.set('v.idSelect', event.getParam('IdItem'));
      cmp.set('v.view', true); // NOSONAR
    }
  },
  refresh: function(cmp, event, helper) {
    cmp.set('v.view', false);
    cmp.set('v.view', true); // NOSONAR
  },
  update: function(component, event, helper) {
    component.destroy();
  },
  handleTabEvent: function(cmp, event, helper) {
    var policies = event.getParam('policies');
    var buttons = cmp.get('v.buttonsIdentifier');
    var buttonStyle = cmp.get('v.buttonsStyle');
    var buttonAlig = cmp.get('v.buttonsAlig');
    var buttonsLts = buttons.split(',');
    var buttonStyleLts = buttonStyle.split(',');
    var buttonAligLts = buttonAlig.split(',');
    var aux = 0;
    if (policies === false) {
      for (var i in buttonsLts) {
        if (buttonsLts[i] === 'Arc_Gen_BtnValidate') {
          buttonsLts[i] = null;
          buttonStyleLts[i] = null;
          buttonAligLts[i] = null;
          cmp.set('v.indexAux', i);
        }
      }
      cmp.set('v.buttonsIdentifier', buttonsLts.toString());
      cmp.set('v.buttonsAlig', buttonAligLts.toString());
      cmp.set('v.buttonsStyle', buttonStyleLts.toString());
    } else {
      for (var j in buttonsLts) {
        if (buttonsLts[j] === 'Arc_Gen_BtnValidate') {
          aux++;
        }
      }
      if (aux === 0) {
        let index = cmp.get('v.indexAux');
        buttonsLts[index] = 'Arc_Gen_BtnValidate';
        buttonStyleLts[index] = 'brand';
        buttonAligLts[index] = 'right';
        cmp.set('v.buttonsIdentifier', buttonsLts.toString());
        cmp.set('v.buttonsStyle', buttonStyleLts.toString());
        cmp.set('v.buttonsAlig', buttonAligLts.toString());
      }
    }
    cmp.set('v.view', false);
    cmp.set('v.view', true); // NOSONAR
  }
});