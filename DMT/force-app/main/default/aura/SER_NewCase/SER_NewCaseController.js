/**
*  Author:
*  Company:
*  Description:  Component Button Case
*
*  History:
*  <Date>      <Author>          <Description>
*  08/07/2017    Juan Carlos Terron      Initial version
*  10/07/2018    Javier Touchard Vicente    New case GM
*  16/07/2018    Victor Velandia        Validation for STE
*  21/11/2018    Victor Velandia        Assigned to RecordType in the case its respective user
*/
({
  doinit: function(component, event, helper) {
    var LblSerClientSerManagerSTE       =   $A.get('$Label.c.SER_Service_Client_Service_Manager_STE');
    var LblSerManagementSTE             =   $A.get('$Label.c.SER_Service_Management_STE');
    var LblSerStandarUserSTE            =   $A.get('$Label.c.SER_Service_Standard_User_STE');
    var LblSerClientSerManagerGNC       =   $A.get('$Label.c.SER_Service_Client_Service_Manager_GNC');
    var LblSerStandarUserGNC            =   $A.get('$Label.c.SER_Service_Standard_User_GNC');


    helper.helperFunctionAsPromise(component, event, helper, helper.initDataHelper)
      .then(function() {
        var currentUserProfile  =  component.get('v.currentuser').Profile.Name;
        var hasPermission       =   component.get('v.hasGTBPermission');

        //GM Y GTB
        if (helper.isGMorGTB(currentUserProfile, hasPermission)) {
          console.log('GM / GTB');
          component.set('v.showSpinner', true);
          helper.saveNewCasHelper(component, event, helper);

          //STE
        } else if (currentUserProfile === LblSerClientSerManagerSTE
          || currentUserProfile === LblSerManagementSTE
          || currentUserProfile === LblSerStandarUserSTE) {
          console.log('STE');
          component.set('v.showBody', true);
          component.set('v.steUser', true);

          //GNC
        } else if (currentUserProfile === LblSerClientSerManagerGNC
          || currentUserProfile === LblSerStandarUserGNC) {
          console.log('GNC');
          component.set('v.showBody', true);
          component.set('v.gncUser', true);
          var wsAPI = component.find('workspace');
          wsAPI.getFocusedTabInfo()
            .then(function(response) {
              var focusedTabID = response.tabId;
              console.log('FTID-oninit-' + focusedTabID);
              component.set('v.previousFocusedTab', focusedTabID);
            }).catch(function(error) {
              console.log(error);
            });

          //Otros
        } else {
          console.log('Otros');
          component.set('v.showSpinner', true);
          helper.saveNewCasHelper(component, event, helper);
        }
      });
  },

  onsave: function(component, event, helper) {
    var recordTypes = helper.getUrlRecordType()['recordTypeId'];
    if (recordTypes !== undefined && recordTypes !== null && recordTypes !== '') {
      component.set('v.strrecordTypes', recordTypes);
      console.log('RT URL', component.get('v.strrecordTypes'));
    }
    if (component.get('v.gncUser')) {
      component.set('v.strrecordTypes', component.get('v.gncRT'));
      console.log('RT GNC', component.get('v.strrecordTypes'));
      helper.getsaveCaseGNC(component, event, helper);
    } else if (component.get('v.steUser')) {
      component.set('v.strrecordTypes', component.get('v.steRT'));
      console.log('RT STE', component.get('v.strrecordTypes'));
      helper.saveCaseSTE(component, event, helper);
    } else {
      var form = component.find('recordEditForm');
      form.submit();
      console.log('form');
    }
  },

  closedAction: function(component, event, helper) {
    var dismissActionPanel = $A.get('e.force:closeQuickAction');
    dismissActionPanel.fire();
  },

  oncancel: function(component, event, helper) {
    var wsAPI = component.find('workspace');
    wsAPI.getFocusedTabInfo()
      .then(
        function(response) {
          var focusedTabID = response.tabId;
          console.log('FTID-oncancel-' + focusedTabID);
          wsAPI.closeTab({ tabId: focusedTabID });
          var dismissActionPanel = $A.get('e.force:closeQuickAction');
          dismissActionPanel.fire();
        }).catch(function(error) {
        console.log(error);
      });
  },

  redirect: function(component, event, helper) {
    var newcaseid = event.getParam('response').id;
    component.set('v.newcaseid', newcaseid);
    if (component.get('v.steUser')) {
      var workspaceAPI = component.find('workspace');
      workspaceAPI.openTab({
        url: '/lightning/r/Case/' + newcaseid + '/view',
      }).then(function(response) {
        var focusedTabID = response;
        workspaceAPI.focusTab({ tabId: focusedTabID });
        helper.closeNewCase(component);
      }).then(function(response) {
        workspaceAPI.openTab({
          url: '/lightning/r/Case/' + newcaseid + '/view',
        });
        var dismissActionPanel = $A.get('e.force:closeQuickAction');
        dismissActionPanel.fire();
      }).catch(function(error) {
        console.log(error);
      });
    } else {
      console.log('Entro al Else diferente de STE');
      helper.redirect_detailPage(component, event, helper, newcaseid);
    }
  },

  originchange: function(component, event, helper) {
  }
});