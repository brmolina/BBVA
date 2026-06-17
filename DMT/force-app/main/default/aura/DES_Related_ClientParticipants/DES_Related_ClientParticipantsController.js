({
  doInit : function(component, event, helper) {
      helper.fetchContactsVisit(component, event);
      //helper.isVisible(component, event);
       helper.checkClosed(component, event, helper);
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
      var codTeamMember = event.getParam("value");
      helper.checkClosed(component, event, helper).then(
          $A.getCallback(function(result) {
              var isClosed = component.get("v.isClosed");
              if(isClosed !== true) {
                  helper.deleteSf(component, event, helper, codTeamMember);
              }
          }),
          $A.getCallback(function(error) {
              console.error( 'Error calling action "' + action + '" with state: ' + error.message );
          }));

  },
  runNewClientParticipant: function(component, event, helper) {

    var actionAPI = component.find("quickActionAPI");
    var args = { actionName :"dwp_kitv__Visit__c.Add_Contact_custom"};
    actionAPI.selectAction(args).then(function(result) {
    }).catch(function(e) {
      if (e.errors) {
      }
    });
  },
  hideSpinner: function (component, helper){
      component.set("v.Spinner", false);
  },
    jsLoaded : function(cmp, event, helper) {
        var lstTopics= [];
        lstTopics.push($A.get('$Label.c.VisitMembersTopic'));
        lstTopics.push($A.get('$Label.c.VisitContactTopic'));

        var jsonResponse = null;
        var actionSession = cmp.get("c.sessionId");

        actionSession.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                jsonResponse = JSON.parse(response.getReturnValue());
                (function($) {
                    $.cometd.init({
                        url: window.location.protocol+'//'+window.location.hostname+'/cometd/44.0/',
                        requestHeaders: { Authorization: 'OAuth '+jsonResponse.sessionId}
                    });
                    for(var i = 0; i<lstTopics.length; i++) {
                        var topic = lstTopics[i].toString();
                        var concatTopic = '/topic/'+ topic;
                        $.cometd.subscribe(concatTopic, function(message) { //NOSONAR
                            helper.auxjsLoaded(message, jsonResponse, cmp, event, helper);
                        });
                    }

                })(jQuery);
            }
        });
        $A.enqueueAction(actionSession);
    }
});