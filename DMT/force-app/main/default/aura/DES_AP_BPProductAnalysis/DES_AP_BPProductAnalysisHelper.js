({
  onInit: function(component, event, helper) {
    var checkaccess = helper.getAccess(component, event, helper);
    var checkedit = checkaccess.then(function() {
      return helper.getEdit(component, event, helper);
    });
    checkedit.then(function() {
      console.log('VALOR DE EDIT : ' + component.get('v.edit'));
    });
    helper.getCountriesBP(component, event, helper);
  },

  getAccess: function(component, event, helper) {
    return new Promise(function(resolve, reject) {
      var getuserpermission = component.get('c.userHasAccess');
      getuserpermission.setParams({
        'accountplanid': component.get('v.recordId')
      });
      getuserpermission.setCallback(this, function(response) {
        var state = response.getState();
        var value = response.getReturnValue();
        console.log('value del access ' + value);
        if (state === 'SUCCESS') {
          resolve(component.set('v.bpaccess', value));
        } else {
          reject(console.log('Error en la llamada a userHasAccess'));
        }
      });
      $A.enqueueAction(getuserpermission);
    });
  },
  getEdit: function(component, event, helper) {
    console.log('get edit');
    return new Promise(function(resolve, reject) {
      var geteditpermission = component.get('c.userHasEditPermission');
      geteditpermission.setParams({
        'accountplanid': component.get('v.recordId'),
        'bpVersionId': component.get('v.bpVersionId')
      });
      geteditpermission.setCallback(this, function(response) {
        var state = response.getState();
        var value = response.getReturnValue();
        if (state === 'SUCCESS') {
          resolve(component.set('v.edit', value));
        } else {
          reject(console.log('Error en la llamada a userHasAccess'));
        }
      });
      $A.enqueueAction(geteditpermission);
    });
  },

    registerEvent : function(component, event, helper) {
        component.set('v.bpVersionId', event.getParam("recordByEvent"));
        console.log('registerEvent en DES: ' + component.get('v.bpVersionId'));
    },
    
   getCountriesBP: function(cmp, event, helper) {
    var getSections = cmp.get('c.getCountriesBP');
    getSections.setParams({
      'recordId': cmp.get('v.recordId'),
      'lastValidatedV': cmp.get('v.lastValidatedVersion')
    });
    getSections.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        console.log('Ha funcionado la llamada al getSections');
        cmp.set('v.sectionList', response.getReturnValue());
        console.log('GetSections devuelve : ' + response.getReturnValue());
      } else {
        console.log('Ha fallado la llamada al getSections');
      }
    });
    $A.enqueueAction(getSections);
  }

});