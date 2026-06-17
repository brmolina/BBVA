({
    helperCreate : function(component, event, helper, iden, storeRes) {
        if(iden !== storeRes) {
            component.set('v.iden', storeRes);
        console.log(storeRes);
            storeRes += "";
            $A.createComponent("forceChatter:publisher", {
                "context": "RECORD",
                "recordId": storeRes
            },
            function(recordFeed) {
            //Add the new button to the body array
                if (component.isValid()) {
                    var body = component.get("v.body");
                    if(iden !== null) {
                        component.set("v.body", []);
                        body = component.get("v.body");
                    }
                    body.push(recordFeed);
                    component.set("v.body", body);
                }
            });
            // Dynamically create the feed with the specified type
            $A.createComponent("forceChatter:feed", {
                "type": "Record",  "subjectId":storeRes
            },
            function(feed) {
                var feedContainer = component.find("feedContainer");
                feedContainer.set("v.body", feed);
            });
        }
    },

    helperMethod : function(component, event, helper, nbc, TemplateId) {
        var selectedOpportunityGetFromEvent = component.get("v.oppSel");
            var act = component.get("c.gtChatterNBC");
            // set param to method
            if(nbc) {
                act.setParams({
                    'iden': selectedOpportunityGetFromEvent,
                });
            } else {
                act.setParams({
                    'iden': TemplateId,
                });
            }
            act.setCallback(this, function (response) {
                var stateStore = response.getState();
                if (stateStore === "SUCCESS") {
                    component.set('v.view', true);
                    var storeRes = response.getReturnValue();
                    var iden = component.get("v.iden");
                    helper.helperCreate(component, event, helper, iden, storeRes);
                    helper.size(component, event, helper, iden);
                } else {
                	component.set('v.view', false);
                }
            });
            $A.enqueueAction(act);
    },
    refrshChat: function(component, event, helper){
        var iden = component.get("v.iden");
        $A.createComponent("forceChatter:publisher", {
                "context": "RECORD",
                "recordId": iden
            },
            function(recordFeed) {
            //Add the new button to the body array
                if (component.isValid()) {
                    var body = component.get("v.body");
                    if(iden !== null) {
                        component.set("v.body", []);
                        body = component.get("v.body");
                    }
                    body.push(recordFeed);
                    component.set("v.body", body);
                }
            });
            // Dynamically create the feed with the specified type
            $A.createComponent("forceChatter:feed", {
                "type": "Record",  "subjectId":iden
            },
            function(feed) {
                var feedContainer = component.find("feedContainer");
                feedContainer.set("v.body", feed);
            });
    },
    size: function(component, event, helper,iden){
        var action = component.get("c.gtChatterUp");
        var lon = component.get("v.lon");
        console.log(lon)
        action.setParams({
            'iden': iden
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                if (response.getReturnValue().length !== 0) {
                    if(lon!== response.getReturnValue()){
                        component.set('v.lon', response.getReturnValue());
                        helper.refrshChat(component, event, helper);
                    }else{
            			component.set('v.lon', response.getReturnValue());
                    }
                }
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                            errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    }
})