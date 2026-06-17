({
    /*isVisible : function(component, event) {
        var actionVisible = component.get("c.isVisible");
        actionVisible.setParams({
            'oppId': component.get('v.recordId')
        })

        var promise = this.executeAction(component, actionVisible);
        return promise.then(
            $A.getCallback(function(result) {
                component.set('{!v.isVisible}', result);
            }),
            $A.getCallback(function(error) {
            })
        ).catch(function(e) {
        });
    },*/
    fetchMembersOpp : function(component, event) {
        var actionMembersOpp = component.get("c.oppMembers");
        actionMembersOpp.setParams({
            'oppId': component.get('v.recordId')
        })
        var promise = this.executeAction(component, actionMembersOpp);
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
    fetchCurrentUser : function(component, event) {
        var actionCurrentUser = component.get("c.bbvaUserCode");

        var promise = this.executeAction(component, actionCurrentUser);
        return promise.then(
            $A.getCallback(function(result) {
                var parsedResult = result;
                if(parsedResult){
                    component.set('{!v.currentUser}', parsedResult);
                }
            }),
            $A.getCallback(function(error) {
            })
        ).catch(function(e) {
        });
    },
    deleteSf: function(component, event, helper, codTeamMember) {
        var actiondeleteSF = component.get("c.delRecord");
        actiondeleteSF.setParams({
            'codTeamMember': codTeamMember,
           	'oppId': component.get('v.recordId')
        })

        var promise = this.executeAction(component, actiondeleteSF);
        return promise.then(
            $A.getCallback(function(result) {
                helper.fetchMembersOpp(component, event);
            }),
            $A.getCallback(function(error) {
            })
        ).catch(function(e) {
        });
    },
    selectOperation : function(component, url, http, codTeamMember) {
        var codOppOwnerFed = component.get('v.currentUser');
        var codOpportunity = component.get('v.recordId');

        url = url + $A.get("$Label.c.DES_IP_URL_OPP") + codOpportunity + $A.get("$Label.c.DES_IP_URL_OPP_MEMBERS") + codTeamMember + "?_method=DELETE";
        http.open("POST", url, true);
        http.withCredentials = true;
        http.setRequestHeader("Content-Type", "application/json");
        http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"),
                              codOppOwnerFed);
        http.send(null);
    },
    // Promise Execute action against the server
    executeAction: function(component, executedaction, callback) {
        return new Promise(function(resolve, reject) {
            executedaction.setCallback(this, function(response) {
                var statusaction = response.getState();
                if (statusaction === 'SUCCESS') {
                    resolve(response.getReturnValue());
                } else if (statusaction === 'ERROR') {
                    var err = response.getError();
                    if (err) {
                        if (err[0] && err[0].message) {
                            reject(
                                Error('Err: ' + err[0].message)
                            );
                        }
                    } else {
                        reject(
                            Error('Uknown error')
                        );
                    }
                }
            });
            $A.enqueueAction(executedaction);
        });
    },
    handleSuccess : function(component, event) {
      var toastEvent = $A.get("e.force:showToast");
      _ipUtils.sucess(toastEvent, "Information has been deleted.", "Success!");
    },
    showSpinner: function (component, helper){
        component.set("v.Spinner", true);
    },
    getIsClosedRelated : function(component, event ) {
      var codTeamMember = event.getParam("value");
      var actionRel = component.get( "c.isOppClosed" );
      var oppId = component.get('v.recordId');
        actionRel.setParams({
            'oppId': oppId,
            'codTeamMember': codTeamMember
        })

      var promiseRel = this.executeAction(component, actionRel);
      return promiseRel.then(
        $A.getCallback(function(result) {
            component.set( 'v.isClosed',  result);
        }),
        $A.getCallback(function(error) {
        console.error( 'Error calling action "' + actionRel + '" with state: ' + error.message );
        })
      ).catch(function(e){
      });
    },

    checkEventTrackerInfo : function(component, event ) {
        var codTeamMember = event.getParam("value");
        var actionRel = component.get( "c.checkEventTracker" );
        var oppId = component.get('v.recordId');
          actionRel.setParams({
              'oppId': oppId,
              'codTeamMember': codTeamMember
          })

        var promiseRel = this.executeAction(component, actionRel);
        return promiseRel.then(
          $A.getCallback(function(result) {
              if(result) {
                component.set('v.isInEvntTracker', true);
                var toast = $A.get('e.force:showToast');
                _ipUtils.errorToast(toast, $A.get("$Label.c.ERROR_IP_CANNOT_DELETE_OPP_MEMBER"));
              } else {
                component.set('v.isInEvntTracker', false);
              }
          }),
          $A.getCallback(function(error) {
          console.error( 'Error calling action "' + actionRel + '" with state: ' + error.message );
          })
        ).catch(function(e){
        });
      },

    delRecrd: function (component, event, helper) {
        var codTeamMember = event.getParam("value");
        return new Promise(
            function(resolve, reject) {
                var http = new XMLHttpRequest();
                var url = component.get( 'v.endpoint');
                http.onreadystatechange = $A.getCallback(function() {
                    if (this.readyState === 4) { // DONE
                        if (this.status >= 200 && this.status < 300) {
                            helper.deleteSf(component, event, helper, codTeamMember);
                            helper.handleSuccess(component, event);
                            resolve();
                        } else {
                            var errorText = "";
                            if (this.status === 0) {
                                errorText = $A.get("$Label.c.DES_ERROR_IP_SERVER");
                            } else {
                                errorText = this.statusText;
                            }
                            reject(new Error(errorText));
                        }
                    }
                });
                helper.selectOperation(component, url, http, codTeamMember);
            }).catch(function(error) {
              console.error(error);
              var toast = $A.get('e.force:showToast');
              _ipUtils.errorToast(toast, $A.get("$Label.c.DES_ERROR_IP_SERVER"));
          });
    },
    getUrlIpOppM : function(component ) {
      var actionUrlOM = component.get( "c.urlIpServices" );

      var promiseUrlOM = this.executeAction(component, actionUrlOM);
      return promiseUrlOM.then(
              $A.getCallback(function(result) {
                  component.set( 'v.endpoint',  result);
              }),
              $A.getCallback(function(error) {
                console.error( 'Error calling action getUrlIp with state: ' + error.message );
              })
      ).catch(function(e){
      });
    }
})