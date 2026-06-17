({
    fetchCurrentUser : function(component, event) {
        var actionUser = component.get("c.bbvaUserCode");

        var promise = this.executeAction(component, actionUser);
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
    fetchMembersVisit : function(component, event) {
        var actionVisitMembers = component.get("c.visitMembers");
        actionVisitMembers.setParams({
            'visitId': component.get('v.recordId')
        })

        var promise = this.executeAction(component, actionVisitMembers);
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
    selectOperation : function(component, url, http, codTeamMember) {
        var codOppOwnerFederationId = component.get('v.currentUser');
        var codExternalOpportunity = component.get('v.recordId');

        url = url + $A.get("$Label.c.DES_IP_URL_VISIT") + codExternalOpportunity + $A.get("$Label.c.DES_IP_URL_OPP_MEMBERS") + codTeamMember + "?_method=DELETE";
        http.open("POST", url, true);
        http.withCredentials = true;
        http.setRequestHeader("Content-Type", "application/json");
        http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"),
                              codOppOwnerFederationId);
        http.send(null);
    },
    deleteSf: function(component, event, helper, codTeamMember) {
        var actionDeleteInSf = component.get("c.delRecord");
        actionDeleteInSf.setParams({
            'codTeamMember': codTeamMember,
            'visitId': component.get('v.recordId')
        })

        var promise = this.executeAction(component, actionDeleteInSf);
        return promise.then(
            $A.getCallback(function(result) {
                helper.fetchMembersVisit(component, event);
            }),
            $A.getCallback(function(error) {
            })
        ).catch(function(e) {
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
                _ipUtils.errorToast(toast, $A.get("$Label.c.ERROR_IP_CANNOT_DELETE_VISIT_MEMBER"));
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
    /*isVisible : function(component, event) {
        var actionVis = component.get("c.isVisible");
        actionVis.setParams({
            'visitId': component.get('v.recordId')
        })

        var promise = this.executeAction(component, actionVis);
        return promise.then(
            $A.getCallback(function(result) {
                component.set('{!v.isVisible}', result);
            }),
            $A.getCallback(function(error) {
            })
        ).catch(function(e) {
        });
    },*/
    // Promise Execute action against the server
    executeAction: function(component, act8, callback) {
        return new Promise(function(resolve, reject) {
            act8.setCallback(this, function(response) {
                var st = response.getState();
                if (st === 'SUCCESS') {
                    resolve(response.getReturnValue());
                } else if (st === 'ERROR') {
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
            $A.enqueueAction(act8);
        });
    },
    handleSuccess : function(component, event) {
      var toastEvt = $A.get("e.force:showToast");
      _ipUtils.sucess(toastEvt, "Information has been deleted.", "Success!");
    },
    showSpinner: function (component, helper){
        component.set("v.Spinner", true);
    },
    checkClosedVM: function(component, event, helper) {
        var actionVM = component.get("c.isVisitClosed");
        actionVM.setParams({
            'codVisit': component.get('v.recordId')
        })
        var promiseVM = this.executeAction(component, actionVM);
          return promiseVM.then(
                  $A.getCallback(function(result) {
                      component.set( 'v.isClosed',  result);
                  }),
                  $A.getCallback(function(error) {
                    console.error( 'Error calling action "' + actionVM + '" with state: ' + error.message );
                  })
          ).catch(function(e){
          });
    },
    deleteVM: function(component, event, helper) {
        var codTeamMember = event.getParam("value");
        return new Promise(
            function(resolve, reject) {
                var http7 = new XMLHttpRequest();
                var url = component.get( 'v.endpoint');
                http7.onreadystatechange = $A
                .getCallback(function() {
                    if (this.readyState === 4) { // DONE
                        if (this.status >= 200 && this.status < 300) {
                            helper.deleteSf(component, event, helper, codTeamMember);
                            helper.handleSuccess(component, event);
                            resolve();
                        } else {
                            var err = "";
                            if (this.status === 0) {
                                err = $A.get("$Label.c.DES_ERROR_IP_SERVER");
                            } else {
                                err = this.statusText;
                            }
                            reject(new Error(err));
                        }
                    }
                });
                helper.selectOperation(component, url, http7, codTeamMember);
            }).catch(function(error) {
              console.error(error);
              var toastEvt = $A.get('e.force:showToast');
              _ipUtils.errorToast(toastEvt, $A.get("$Label.c.DES_ERROR_IP_SERVER"));
          });
    },
    getUrlIpOppVM : function(component ) {
      var actionUrlVM = component.get( "c.urlIpServices" );

      var promiseUrlVM = this.executeAction(component, actionUrlVM);
      return promiseUrlVM.then(
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