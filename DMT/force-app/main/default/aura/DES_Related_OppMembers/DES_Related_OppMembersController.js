({
    doInit : function(component, event, helper) {
       helper.getUrlIpOppM(component, event, helper).then(
              $A.getCallback(function(result) {
                 helper.fetchMembersOpp(component, event);
                 //helper.isVisible(component, event);
                 helper.fetchCurrentUser(component, event);
                 helper.getIsClosedRelated(component,event);
              }),
              $A.getCallback(function(error) {
                console.error( 'Error calling action getUrlIp with state: ' + error.message );
              }));

    },
    deleteRecord: function (component, event, helper) {

        helper.showSpinner(component, helper);
        helper.checkEventTrackerInfo(component, event);
        helper.getIsClosedRelated(component, event).then(
            $A.getCallback(function(result) {
                var isClosed = component.get("v.isClosed");
                var isInEvntTracker = component.get("v.isInEvntTracker");
                if(isClosed !== true && isInEvntTracker !== true){
                    helper.delRecrd(component, event, helper);
                }
            }),
            $A.getCallback(function(error) {
                console.error( 'Error calling action "' + action + '" with state: ' + error.message );
            })
        );

    },
    navigateRecord: function(component, event, helper) {
        var target = event.target.id;
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId" : target
        });
        navEvt.fire();
    },
    jsLoaded : function(cmp, evt, helper) {
    var jsonResponse = null;
    var actionSessionId = cmp.get("c.sessionId");

        actionSessionId.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                jsonResponse = JSON.parse(response.getReturnValue());
                (function($) {
                    $.cometd.init({
                        url: window.location.protocol+'//'+window.location.hostname+'/cometd/44.0/',
                        requestHeaders: { Authorization: 'OAuth '+jsonResponse.sessionId}
                    });

                    var currentTopic = $A.get("$Label.c.OpportunityMembersTopic");
                    var strTopic = '/topic/'+currentTopic;
                    $.cometd.subscribe(strTopic, function(message) {
                        var strApiNameCompare = 'DES_Opportunity__c';
                        if ((jsonResponse.userId ===  message.data.sobject.CreatedById || jsonResponse.userId ===  message.data.sobject.OwnerId)
                            && cmp.get('v.recordId') === message.data.sobject[strApiNameCompare] ) {
                            if (currentTopic === $A.get("$Label.c.OpportunityMembersTopic")) {
                                helper.fetchMembersOpp(cmp, evt);
                            }
                        }
                    });
                })(jQuery);
            }
        });
        $A.enqueueAction(actionSessionId);
    },
    hideSpinner: function (component, helper){
        component.set("v.Spinner", false);
    }
})