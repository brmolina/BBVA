({
    doInit: function(component, event, helper) {
        helper.getUrlIpOppT(component, event, helper).then(
        	$A.getCallback(function(result) {
        helper.fetchVisitTopics(component, event, helper);
        helper.isVisible(component, event);
        helper.fetchCurrentUser(component, event);
        helper.checkClosedVT(component, event, helper);
            }),
            $A.getCallback(function(error) {
                console.error( 'Error calling action getUrlIp with state: ' + error.message );
            }));
    },
    navigateRecord: function(component, event, helper) {
        var idx = event.target.id;
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": idx
        });
        navEvt.fire();
    },
    option: function (component, event, helper) {
      var optionSelected = event.getParam("value").split("_")[0];
      var codVisitTopic = event.getParam("value").split("_")[1];
      var descVisitTopic = event.getParam("value").split("_")[2];
      var opportunityName = event.getParam("value").split("_")[3];
      if(optionSelected === 'Edit') {
        helper.editRecord(component, event, helper, codVisitTopic, descVisitTopic, opportunityName);
      } else if(optionSelected === 'Delete'){
        helper.deleteRecord(component, event, helper, codVisitTopic);
      }
    },
    closeFlowModal: function(component, event, helper) {
        component.set("v.isOpen", false);
    },

    closeModalOnFinish: function(component, event, helper) {
        if(event.getParam('status') === "FINISHED") {
            var outputVariables = event.getParam("outputVariables");
            for(var i = 0; i < outputVariables.length; i++) {
                if(outputVariables[i].name === "hasError" && outputVariables[i].value === true) {
                    var toast = $A.get('e.force:showToast');
                    _ipUtils.errorToast(toast, $A.get("$Label.c.DES_ERROR_IP_SERVER"));
                }
            }
            component.set("v.isOpen", false);
        }
    },
    runNewTopicFlow: function (component, event, helper) {
        component.set("v.isOpen", true);
        var flow = component.find("New_Visit_Topic");
        var inputVariables = [
            { name: "recordId", type: "String", value: component.get("v.recordId") }];
        flow.startFlow("New_Visit_Topic", inputVariables);
    },
    hideSpinner: function (component, helper){
        component.set("v.Spinner", false);
    }
});