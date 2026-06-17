({
    doInit : function(component, event, helper) {
        helper.getUrlIpOppVM(component, event, helper).then(
          $A.getCallback(function(result) {
                helper.fetchMembersVisit(component, event);
                //helper.isVisible(component, event);
                helper.fetchCurrentUser(component, event);
                helper.checkClosedVM(component, event, helper);
            }),
            $A.getCallback(function(error) {
                console.error( 'Error calling action getUrlIp with state: ' + error.message );
            }));
    },
    navigateRecord: function(component, event, helper) {
        var idx = event.target.id;
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId" : idx
        });
        navEvt.fire();
    },
    deleteRecord: function (component, event, helper) {
        helper.showSpinner(component, helper);
        helper.checkEventTrackerInfo(component, event);
        helper.checkClosedVM(component, event, helper).then(
          $A.getCallback(function(result) {
              var isClosed = component.get("v.isClosed");
              var isInEvntTracker = component.get("v.isInEvntTracker");
              if(isClosed !== true && isInEvntTracker !== true){
                helper.deleteVM(component, event, helper);
              }
          }),
          $A.getCallback(function(error) {
              console.error( 'Error calling action "' + action + '" with state: ' + error.message );
          }));
    },
    closeFlowModal : function(component, event, helper) {
        component.set("v.isOpen", false);
    },

    closeModalOnFinish : function(component, event, helper) {
        if(event.getParam('status') === "FINISHED") {
            component.set("v.isOpen", false);
            helper.fetchMembersVisit(component, event);
        } else if (event.getParam('status') === "ERROR") {
            component.set("v.isOpen", false);
            var toastEvt = $A.get('e.force:showToast');
            _ipUtils.errorToast(toastEvt, 'You cannot insert the Owner of the visit or a member that already exists.');
        }
    },
    runNewBBVAParticipantFlow: function (component, event, helper) {
        component.set("v.isOpen", true);
        var flow = component.find("New_Visit_BBVA_Participant");
        var inputVariables = [
            { name : "recordId", type : "String", value: component.get("v.recordId") }];
        flow.startFlow("New_Visit_BBVA_Participant", inputVariables);
    },
    hideSpinner: function (component, helper){
        component.set("v.Spinner", false);
    }
})