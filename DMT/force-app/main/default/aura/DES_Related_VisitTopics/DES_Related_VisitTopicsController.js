({
    doInit : function(component, event, helper) {
        helper.getUrlIpOppVT(component, event, helper).then(
        	$A.getCallback(function(result) {
        helper.fetchTopicsOpp(component, event);
                //helper.isVisible(component, event);
        helper.fetchTopicsCurrentUser(component, event);
            }),
            $A.getCallback(function(error) {
                console.error( 'Error calling action getUrlIp with state: ' + error.message );
            }));
    },
    navigateToRecord: function(component, event, helper) {
        var targetVisit = event.target.id;
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId" : targetVisit
        });
        navEvt.fire();
    }
})