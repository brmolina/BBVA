({
    helperCreate : function(component, event, helper, iden, storeRes) {
        if(iden !== storeRes) {
            component.set('v.iden', storeRes);
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
        var selectedOpportunityGetFromEvent = event.getParam("IdItem");
        component.set("v.oppSel", selectedOpportunityGetFromEvent);
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
                } else {
                	component.set('v.view', false);
                }
            });
            $A.enqueueAction(act);
    },

	helperPost :function(component, event, storeRes, post){
        console.log('Entro a helperPost');
        var act = component.get("c.generarPostChatter");
        act.setParams({
            'iden' : storeRes,
            'post' : post
        });
        act.setCallback(this, function (response) {
            var stateStore = response.getState();
            if (stateStore === "SUCCESS") {
                console.log('Se ha insertado el comentario correctamente');
                location.reload();
            } else {
                console.log('NO se ha insertado el comentario correctamente');
            }
        });
        $A.enqueueAction(act);
    },

    helperMobile :function(component, event, nbc, TemplateId, helper){
        var selectedOpportunityGetFromEvent =component.get('v.oppSel');
        var post = component.get('v.myVal');
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
                var storeRes = response.getReturnValue();
                storeRes += "";
                helper.helperPost(component, event, storeRes, post);
            }
        });
        $A.enqueueAction(act);
    },

})