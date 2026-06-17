({
    initComponent: function(cmp, event, helper) {
        cmp.set('v.isVisible', false);
        var recordId = cmp.get('v.recordId');
        var optyId = cmp.get('v.visitId');

        if (optyId === undefined) {
            cmp.set('v.visitId', recordId);
        }

        helper.getRTName(cmp, event, helper);
    helper.fetchCurrentUser(cmp, event, helper).then(
            $A.getCallback(function(result) {
                //helper.isVisible(cmp, event, helper).then(
                    //$A.getCallback(function(result) {
                        helper.fetchConfidentialData(cmp, event, helper).catch(function(error) {
                        })
                    //}),
                    //$A.getCallback(function(error) {
                    //})
                //).catch(function(e){
                //});
            }),
            $A.getCallback(function(error) {
            })
        );
    },
    // Promise Execute action against the server
    executeAction: function(cmp, action, callback) {
        return new Promise(function(resolve, reject) {
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === 'SUCCESS') {
                    resolve(response.getReturnValue());
                } else if (state === 'ERROR') {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            reject(Error('Error message: ' + errors[0].message));
                        }
                    } else {
                        reject(Error('Unknown error'));
                    }
                }
            });
            $A.enqueueAction(action);
        });
    },
    fetchCurrentUser : function(component, event) {
        var actionCurrentUser = component.get("c.bbvaUserCode");

        var promiseaction = this.executeAction(component, actionCurrentUser);
        return promiseaction.then(
            $A.getCallback(function(result) {
                component.set('{!v.codUser}', result);
            }),
            $A.getCallback(function(error) {
            })
        ).catch(function(e) {
        });
    },
    fetchConfidentialData: function(component, event, helper) {
        return new Promise(function(resolve, reject) {
            var http = new XMLHttpRequest();

            http.onreadystatechange = $A.getCallback(function() {
              if (this.readyState === 4) { // DONE
                  if (this.status >= 200 && this.status < 300) {
                    component.set('v.isVisible', true);
                      helper.parseConfidentialData(component, event, helper, http);
                      resolve();
                  } else {
                    component.set('v.isVisible', false);
                      var errorText = "";
                      if (this.status === 0) {
                          errorText = $A.get("$Label.c.DES_ERROR_IP_SERVER");
                      } else {
                          errorText = this.statusText;
                      }
                      reject(errorText);
                  }

              }
            });

            helper.callConfidentialData(component, http);
        });
    },
    showHide : function(component) {
        var editForm = component.find("editForm");
        $A.util.toggleClass(editForm, "slds-hide");
        var viewForm = component.find("viewForm");
        $A.util.toggleClass(viewForm, "slds-hide");
    },
    showHideIP : function(component) {
      var editForm = component.find("editFormIP");
      $A.util.toggleClass(editForm, "slds-hide");
      var viewForm = component.find("viewFormIP");
      $A.util.toggleClass(viewForm, "slds-hide");
    },
    modifyOpp : function(component){
        return new Promise(function(resolve, reject) {
            var http = new XMLHttpRequest();

            http.onreadystatechange = $A.getCallback(function() {
                if (this.readyState === 4) { // DONE
                    if (this.status >= 200 && this.status < 300) {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                        "title": "Success!",
                        "message": "Inside information has been updated.",
                        "type": "success"
                        });
                        toastEvent.fire();
                        resolve();
                    } else {
                        var errorText = "";
                        if (this.status === 0) {
                          errorText = $A.get("$Label.c.DES_ERROR_IP_SERVER");
                            reject(Error(errorText));
                        } else {
                            errorText = this.statusText;
                            reject(Error(errorText));
                        }

                    }
                }
            });

             var url = component.get( 'v.endpoint');
              url = url + $A.get("$Label.c.DES_IP_URL_VISIT");

            var externalId = component.get('v.recordId');
            var codUser = component.get('v.codUser');
            var opp = component.get('v.visit');


            if (externalId != null && externalId !=="") {
                 url = url + externalId + "?_method=PUT";
                var jsonOpp = JSON.stringify(opp);

                http.open("POST", url, true);
                http.withCredentials = true;
                http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"), codUser);
                http.setRequestHeader("Content-Type", "application/json");
                http.send(jsonOpp);
            }
        });
    },
    parseConfidentialData: function(component,event,helper, http ){
      var response = JSON.parse(http.responseText);
      if (response != null && response !=="") {
          component.set("v.visit", response);
          helper.getLabels(component,event,helper).catch(function(e) {
          });
      }
    },
    callConfidentialData: function(component, http){
      var url = component.get( 'v.endpoint');
      url = url + $A.get("$Label.c.DES_IP_URL_VISIT");

      var externalId = component.get('v.recordId');
      var codUser = component.get('v.codUser');
      if (externalId != null && externalId !=="") {
        url= url+externalId;
        http.open("GET", url, true);
        http.withCredentials = true;
        http.setRequestHeader("Content-Type", "application/json");
        http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"), codUser);
        http.send(null);
      }
    },
     getLabels : function(component, event, helper) {
      var action = component.get( "c.getObjectType" );
      action.setParams({
          "objeto": 'dwp_kitv__Visit__c'
      });
      var promise = this.executeAction(component, action);
      return promise.then(
              $A.getCallback(function(result) {
                  component.set( 'v.ObjectType', JSON.parse( result));
              }),
              $A.getCallback(function(error) {
                console.error( 'Error calling action "' + action + '" with state: ' + error.message );
              })
      ).catch(function(e){
      });
    },
    getRTName: function(component, event, helper) {
        var action = component.get("c.getRecordTypeId");
        action.setParams({
            'sObjecType': 'dwp_kitv__Visit__c',
            'rtName': $A.get("$Label.c.DES_RT_Inside_Visit")
        })
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS" && response.getReturnValue() !== null && response.getReturnValue() !== undefined) {
                component.set("v.rtId", response.getReturnValue());
            }
        })
        $A.enqueueAction(action);
    },
    // isVisible : function(component, event) {
    //     var actionIsVisible = component.get("c.isVisible");
    //     actionIsVisible.setParams({
    //         'visitId': component.get('v.recordId')
    //     })

    //     var promise = this.executeAction(component, actionIsVisible);
    //     return promise.then(
    //         $A.getCallback(function(result) {
    //             //component.set('{!v.isVisible}', result);
    //         }),
    //         $A.getCallback(function(error) {
    //         })
    //     ).catch(function(e) {
    //     });
    // },

    getUrlIpOppV : function(component ) {
      var actionUrlV = component.get( "c.urlIpServices" );

      var promiseUrlV = this.executeAction(component, actionUrlV);
      return promiseUrlV.then(
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