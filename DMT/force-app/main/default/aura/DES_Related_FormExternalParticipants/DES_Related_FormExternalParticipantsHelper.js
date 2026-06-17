({
    isVisible : function(component, event) {
        var action = component.get("c.isVisible");
        action.setParams({
            'visitId': component.get('v.recordId')
        })

        var promise = this.executeAction(component, action);
        return promise.then(
            $A.getCallback(function(result) {
                var parsedResult = result;
                component.set('{!v.isVisible}', parsedResult);
            }),
            $A.getCallback(function(error) {
            })
        ).catch(function(e) {
        });
    },

    fetchContactsVisit : function(component, event) {
        var action = component.get("c.formExtMembers");
        action.setParams({
            'formId': component.get('v.recordId')
        })

        var promise = this.executeAction(component, action);
        return promise.then(
            $A.getCallback(function(result) {
                var parsedResult = JSON.parse(result);
                if(parsedResult){
                    component.set('v.members', parsedResult);
                    component.set('v.sizeMembers', parsedResult.length);
                }
            }),
            $A.getCallback(function(error) {
            })
        ).catch(function(e) {
        });
    },

    deleteSf: function(component, event, helper, codTeamMember) {
        var action = component.get("c.delContactRecord");
        action.setParams({
            'codTeamMember': codTeamMember,
            'formId': component.get('v.recordId')
        })

        var promise = this.executeAction(component, action);
        return promise.then(
            $A.getCallback(function(result) {
                helper.fetchContactsVisit(component, event);
                helper.handleSuccess(component, event);
            }),
            $A.getCallback(function(error) {
            })
        ).catch(function(e) {
        });
    },
    // Promise Execute action against the server
    executeAction: function(component, actionExecuted, callback) {
        return new Promise(function(resolve, reject) {
            actionExecuted.setCallback(this, function(response) {
                var actionStatus = response.getState();
                if (actionStatus === 'SUCCESS') {
                    resolve(response.getReturnValue());
                } else if (actionStatus === 'ERROR') {
                    var err = response.getError();
                    if (err) {
                        if (err[0] && err[0].message) {
                            reject(
                                Error('Err: ' + err[0].message)
                            );
                        }
                    } else {
                        reject(
                            Error('Uknw err')
                        );
                    }
                }
            });
            $A.enqueueAction(actionExecuted);
        });
    },
    handleSuccess : function(component, event) {
      var toastEvent = $A.get("e.force:showToast");
      _ipUtils.sucess(toastEvent, "Information has been deleted.", "Success!");
    },
    showSpinner: function (component, helper){
        component.set("v.Spinner", true);
    },
     checkClosed: function(component, event, helper) {
        var actionCp = component.get("c.isVisitClosed");
        actionCp.setParams({
            'codVisit': component.get('v.recordId')
        })
        var promiseCp = this.executeAction(component, actionCp);
          return promiseCp.then(
                  $A.getCallback(function(result) {
                      component.set( 'v.isClosed',  result);
                  }),
                  $A.getCallback(function(error) {
                    console.error( 'Error calling action "' + actionCp + '" with state: ' + error.message );
                  })
          ).catch(function(e){
          });
    },
    auxjsLoaded: function(message, jsonResponse, cmp, event, helper) {
        var strApiNameCompare = 'dwp_kitv__visit_id__c';
        var lstCurrentTopic = message.channel.split('/');
        var currentTopic = lstCurrentTopic[lstCurrentTopic.length - 1];
        if ((jsonResponse.userId ===  message.data.sobject.CreatedById || jsonResponse.userId ===  message.data.sobject.OwnerId)
            && cmp.get('v.recordId') === message.data.sobject[strApiNameCompare] ) {
            if (currentTopic === $A.get("$Label.c.VisitContactTopic")) {
                helper.fetchContactsVisit(cmp, event);
            } else if(currentTopic === $A.get("$Label.c.VisitMembersTopic")) {
                $A.get('e.force:refreshView').fire();
            }
        }
    }
})