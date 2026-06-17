({
  getsaveCaseGNC: function(component, event, helper) {
    var LblSerReqMesGNC =   $A.get('$Label.c.SER_SerReqMessageGNC');
    if (component.find('AccountId').get('v.value') !== null && component.find('AccountId').get('v.value') !== ''
        && component.find('Origin').get('v.value') !== '' && component.find('Origin').get('v.value') !== null) {
      var action      =    component.get('c.getDataCaseGNC');
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {

          component.set('v.stMailingGroupGNC', response.getReturnValue().stMailingGroupGNC);
          var mailGroupGNC = component.get('v.stMailingGroupGNC');
          console.log('--->>>> mailGroupGNC'  + mailGroupGNC);

          component.set('v.strOutboundMailboxGNC', response.getReturnValue().strEmailOutboxGNC);
          var EmailOutboxGNC = component.get('v.strOutboundMailboxGNC');
          console.log('--->>>> EmailOutboxGNC ' + EmailOutboxGNC);

          var form      =     component.find('recordEditForm');
          form.submit();
        } else if (state === 'ERROR') {
          helper.errorHandler(response, component, helper);
        }
      });
      $A.enqueueAction(action);
    } else {
      var toastEvent = $A.get('e.force:showToast');
      toastEvent.setParams({
        title: 'Error Message',
        message: LblSerReqMesGNC,
        type: 'error',
        mode: 'pester'
      });
      toastEvent.fire();
    }
  },

  saveCaseSTE: function(component, event, helper) {
    var LblSerReqMesSTE = $A.get('$Label.c.SER_SerReqMessageSTE');
    if (component.find('SER_Transactional_Reference__c').get('v.value') !== null
        && component.find('SER_Transactional_Reference__c').get('v.value') !== '') {
      var action      =     component.get('c.getDataTransCaseSTE');
      action.setParams({'idProduct': component.find('SER_Transactional_Reference__c').get('v.value')});
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {

          component.set('v.strMailingGroupSTE', response.getReturnValue().strMailGroupSTE);
          var strMailingGroupSTE = component.get('v.strMailingGroupSTE');
          console.log('--->>>> strMailingGroupSTE ' + strMailingGroupSTE);

          component.set('v.strOutboundMailboxSTE', response.getReturnValue().strEmailboxSTE);
          var strOutboundMailboxSTE  = component.get('v.strOutboundMailboxSTE');
          console.log('--->>>> strOutboundMailboxSTE ' + strOutboundMailboxSTE);

          component.set('v.strProduct', response.getReturnValue().ssttProduct.SER_Product_Text__c);
          var strProduct = component.get('v.strProduct');
          console.log('--->>>> strProduct ' + strProduct);

          component.set('v.strClient', response.getReturnValue().ssttProduct.SER_Account__c);
          var strClient = component.get('v.strClient');
          console.log('--->>>> strClient ' + strClient);

          var form    =   component.find('recordEditForm');
          form.submit();
        } else if (state === 'ERROR') {
          helper.errorHandler(response, component, helper);
        }
      });
      $A.enqueueAction(action);
    } else {
      var toastEvent = $A.get('e.force:showToast');
      toastEvent.setParams({
        title: 'Error Message',
        message: LblSerReqMesSTE,
        type: 'error',
        mode: 'pester'
      });
      toastEvent.fire();
    }
  },

  closeNewCase: function(component) {
    var wsAPI = component.find('workspace');
    wsAPI.getAllTabInfo()
      .then(function(response) {
        var i = 0;
        for (i; i < response.length; i++) {
          response[i].active = false;
          if (response[i].title === 'New Case' || response[i].title === 'Nuevo Caso') {
            wsAPI.closeTab({tabId: response[i].tabId});
          }
        }
        var dismissActionPanel = $A.get('e.force:closeQuickAction');
        dismissActionPanel.fire();
      }).catch(function(error) {
        console.log(error);
      });
  },

  redirect_detailPage: function(component, event, helper, id) {
    console.log('Entering --> SER_NewCaseHelper : redirect_detailPage');
    console.log('Case Id -->' + id);
    component.set('v.showSpinner', false);
    var wsAPI = component.find('workspace');
    wsAPI.openTab({
      url: '/lightning/r/Case/' + id + '/view',
    }).then(function(response) {
      var focusedTabID = response;
      wsAPI.focusTab({tabId: focusedTabID});
      helper.closeNewCase(component);
    }).catch(function(error) {
      console.log(error);
    });
  },

  initDataHelper: function(component, event, helper, resolve) {
    console.log('Entering --> SER_NewCaseHelper : initDataHelper');
    var userId = $A.get('$SObjectType.CurrentUser.Id');
    console.log('current User Id -->' + userId);
    var params = {'userid': userId};
    var fncallback = function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        component.set('v.currentuser', response.getReturnValue().user);
        component.set('v.gncRT', response.getReturnValue().gncRT);
        component.set('v.steRT', response.getReturnValue().steRT);
        component.set('v.hasGTBPermission', response.getReturnValue().hasGTBPS);
        resolve('Resolved');
      } else if (state === 'ERROR') {
        helper.errorHandler(response, component, helper);
      }
    };
    helper.callServer(component, event, 'c.initData', params, fncallback, helper);
  },

  saveNewCasHelper: function(component, event, helper) {
    console.log('Entering --> SER_NewCaseHelper : saveNewCasHelper');
    var userId = $A.get('$SObjectType.CurrentUser.Id');
    console.log('current User Id -->' + userId);
    var strrecordTypes = helper.getUrlRecordType()['recordTypeId'];
    console.log('strrecordTypes -->' + strrecordTypes);
    var params = {
      'userid': userId,
      'recordType': strrecordTypes
    };
    var fncallback = function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        component.set('v.newcaseId', response.getReturnValue());
        helper.redirect_detailPage(component, event, helper, response.getReturnValue());
      } else if (state === 'ERROR') {
        helper.errorHandler(response, component, helper);
      }
    };
    helper.callServer(component, event, 'c.saveNewCase', params, fncallback, helper);
  },

  getUrlRecordType: function() {
    var strrecordTypes = {};
    window.location.href.replace(/[?&]+([^=&]+)=([^&]*)/gi,
      function(m, key, value) {
        strrecordTypes[key] = value;
      });
    return strrecordTypes;
  },

  errorHandler: function(response, component, helper) {
    var errors = response.getError();
    if (errors[0] && errors[0].message) {
      console.log('Error message: ' + errors[0].message);
      helper.closeNewCase(component);
      helper.showToastError(response.getError()[0].message, 'error');
    }
  },

  isGMorGTB: function(currentUserProfile, hasPermission) {
    var LblSerStandarUserGM             =   $A.get('$Label.c.SER_Service_Standard_User_GM');
    var LblSerClaimsUserGM              =   $A.get('$Label.c.SER_Service_Claims_User_GM');
    var LblSerGlobalManager             =   $A.get('$Label.c.SER_Service_Global_Manager');
    var LblSerClientSerManagerGM        =   $A.get('$Label.c.SER_Service_Client_Service_Manager_GM');
    var LblSerSupplierStandUserGM       =   $A.get('$Label.c.SER_Service_Supplier_Standard_User_GM');
    var LblSerBusinessDevelopmentGTB    =   $A.get('$Label.c.SER_BBVA_Desktop_GTB_Business_Development');
    var LblSerStandardGTB               =   $A.get('$Label.c.SER_BBVA_Desktop_GTB_Standard');
    return currentUserProfile  === LblSerStandarUserGM
          || currentUserProfile   === LblSerClaimsUserGM
          || currentUserProfile   === LblSerGlobalManager
          || currentUserProfile   === LblSerClientSerManagerGM
          || currentUserProfile   === LblSerSupplierStandUserGM
          || (currentUserProfile  === LblSerBusinessDevelopmentGTB && hasPermission)
          || (currentUserProfile  === LblSerStandardGTB && hasPermission);
  }
});