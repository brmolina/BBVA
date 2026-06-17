({
    initComponent: function(cmp, event, helper) {
        cmp.set('v.isVisible', false); ////

        helper.getLabels(cmp,event,helper).catch(function(e) {
        });
		helper.getQuestions(cmp,event,helper).catch(function(e) {
        });
        helper.getRTName(cmp,event,helper);

		helper.getOppId(cmp, event, helper).then(
            $A.getCallback(function(result) {
                helper.getVisitId(cmp, event, helper).then(
            		$A.getCallback(function(result) {
                        helper.fetchCurrentUser(cmp, event, helper).then(
                            $A.getCallback(function(result) {
                                helper.fetchConfidentialData(cmp, event, helper).then(
                                    $A.getCallback(function(result) {
                                        helper.fetchListedData(cmp,event,helper).catch(function(e) {
                                        });
                                    }),
                                    $A.getCallback(function(error) {
                                    })
                                )
                            }),
                            $A.getCallback(function(error) {
                            })
                        );
                	}),
            		$A.getCallback(function(error) {
            		})
                );
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

    showHide : function(component) {
        let hasEditAccess = component.get('v.userAccess').HasEditAccess;
        if ( hasEditAccess ) {
            var editForm = component.find("editForm");
            $A.util.toggleClass(editForm, "slds-hide");
            var viewForm = component.find("viewForm");
            $A.util.toggleClass(viewForm, "slds-hide");
        }

    },
    showHideIP : function(component) {

        let hasEditAccess = component.get('v.userAccess').HasEditAccess;


        if ( hasEditAccess ) {

          var editForm = component.find("editFormIP1");
          $A.util.toggleClass(editForm, "slds-hide");
          var editForm2 = component.find("editFormIP2");
          $A.util.toggleClass(editForm2, "slds-hide");
          var viewForm = component.find("viewFormIP");
          $A.util.toggleClass(viewForm, "slds-hide");
          var viewForm2 = component.find("viewFormIP2");
          $A.util.toggleClass(viewForm2, "slds-hide");

        }

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

            var externalId = component.get('v.recordId');
            var codUser = component.get('v.codUser');
            var formExt = component.get('v.formExt');
            var opp = component.get('v.oppId');
            var visit = component.get('v.visitId');
            var form =component.get('v.form');
            
            if (externalId != null && externalId !=="") {
       			if(opp === null){
         			url= url+ $A.get("$Label.c.DES_IP_URL_VISIT") + visit+ $A.get("$Label.c.DES_IP_URL_OPP_FORM") + externalId + "?_method=PUT";                 
                } else {
                	url= url+$A.get("$Label.c.DES_IP_URL_OPP")+ opp + $A.get("$Label.c.DES_IP_URL_OPP_FORM") + externalId + "?_method=PUT";    
                }
                var jsonOpp = JSON.stringify(formExt);

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
          component.set("v.formExt", response);
      }
    },
    callConfidentialData: function(component, http){
	  var url = component.get( 'v.endpoint');
      var opp = component.get('v.oppId');
      var visit = component.get('v.visitId');
      var form =component.get('v.form');

      var externalId = component.get('v.recordId');
      var codUser = component.get('v.codUser');
      if (externalId != null && externalId !=="") {
        if(opp === null){
         	url= url+ $A.get("$Label.c.DES_IP_URL_VISIT") + visit+ $A.get("$Label.c.DES_IP_URL_OPP_FORM") + externalId;
        }else {
          	url= url+$A.get("$Label.c.DES_IP_URL_OPP")+ opp + $A.get("$Label.c.DES_IP_URL_OPP_FORM") + externalId;
        }  
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
          "objeto": 'Inside_information_form__c'
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
            /*'sObjecType': 'Inside_information_form__c',*/
            'rtName': $A.get("$Label.c.DES_RT_Inside_form")
        })
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS" && response.getReturnValue() !== null && response.getReturnValue() !== undefined) {
                component.set("v.rtId", response.getReturnValue());
            }
        })
        $A.enqueueAction(action);
    },

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
    },
    getQuestions: function(component, event, helper) {
        var action = component.get("c.complianceQuestions");
        var promiseQ = this.executeAction(component, action);
        return promiseQ.then(
              $A.getCallback(function(result) {
                  component.set( 'v.preguntas',  result);
              }),
              $A.getCallback(function(error) {
                console.error( 'Error calling action getQuestions with state: ' + error.message );
              })
        ).catch(function(e){
        });
    },

    fetchConfidentialData: function(component, event, helper) {
        return new Promise(function(resolve, reject) {
            var http = new XMLHttpRequest();

            http.onreadystatechange = $A.getCallback(function() {
              if (this.readyState === 4) { // DONE
                  if (this.status >= 200 && this.status < 300) {
                      helper.parseConfidentialData(component, event, helper, http);
                      component.set('v.isVisible', true);////
                      resolve();
                  } else {
                      component.set('v.isVisible', false);////
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
    getOppId : function(component ) {
      var actionOppId = component.get( "c.getOppId" );
	  var externalId = component.get('v.recordId');
      actionOppId.setParams({
          "formId": externalId
      });

      var promiseOppId = this.executeAction(component, actionOppId);
      return promiseOppId.then(
              $A.getCallback(function(result) {
                  component.set( 'v.oppId',  result);
              }),
              $A.getCallback(function(error) {
                console.error( 'Error calling action getUrlIp with state: ' + error.message );
              })
      ).catch(function(e){
      });       
    },
    getVisitId : function(component ) {
	  var actionVisitId = component.get( "c.getVisitId" );
	  var externalId = component.get('v.recordId');

      actionVisitId.setParams({
          "formId": externalId
      });
      var promiseVisitId = this.executeAction(component, actionVisitId);
      return promiseVisitId.then(
              $A.getCallback(function(result) {
                  component.set( 'v.visitId',  result);
              }),
              $A.getCallback(function(error) {
                console.error( 'Error calling action getUrlIp with state: ' + error.message );
              })
      ).catch(function(e){
      });  
        
    },
    parseListedData: function(component,event,helper, http ){
      var response = JSON.parse(http.responseText);
        if (response != null && response !=="") {
          component.set("v.aListed", response);
      }
    },
     defaultListedData: function(component,event,helper ){
         component.set('v.aListed',JSON.parse('[ { } ]') );
    },
    callListedData: function(component, http){
	  var url = component.get( 'v.endpoint');

      var externalId = component.get('v.recordId');
      var codUser = component.get('v.codUser');
      if (externalId != null && externalId !=="") {
        url= url+$A.get("$Label.c.DES_IP_URL_BASE")+ $A.get("$Label.c.DES_IP_URL_OPP_FORM") + externalId + $A.get("$Label.c.DES_IP_COMPANY") + $A.get("$Label.c.DES_IP_LIST");
        http.open("GET", url, true);
        http.withCredentials = true;
        http.setRequestHeader("Content-Type", "application/json");
        http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"), codUser);
        http.send(null);
      }
    },
    fetchListedData: function(component, event, helper) {
        return new Promise(function(resolve, reject) {
            var http = new XMLHttpRequest();

            http.onreadystatechange = $A.getCallback(function() {
              if (this.readyState === 4) { // DONE
                  if (this.status >= 200 && this.status < 300) {
                      helper.parseListedData(component, event, helper, http);
                      resolve();
                  } else {
                      var errorText = "";
                      if (this.status === 0) {
                          errorText = $A.get("$Label.c.DES_ERROR_IP_SERVER");
                      } else {
                          errorText = this.statusText;
                      }
                      helper.defaultListedData(component, event, helper);
                      reject(errorText);
                  }

              }
            });

            helper.callListedData(component, http);
        });
    },
    modifyListed : function(component,event,helper,listed){
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

            var externalId = component.get('v.recordId');
            var codUser = component.get('v.codUser');

            if (externalId != null && externalId !=="") {
        		url= url + $A.get("$Label.c.DES_IP_URL_BASE")+ $A.get("$Label.c.DES_IP_URL_OPP_FORM") + externalId + $A.get("$Label.c.DES_IP_COMPANY") + listed.codListedCompany + "?_method=PUT";
                var jsonOpp = JSON.stringify(listed);

                http.open("POST", url, true);
                http.withCredentials = true;
                http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"), codUser);
                http.setRequestHeader("Content-Type", "application/json");
                http.send(jsonOpp);
            }
        });
    },
    updateListed: function(component, event, helper){
        var aListed = component.get("v.aListed");
        if (aListed !== null) {
          for (var i = 0; i < aListed.length; i++) {
              if (aListed[i] !== null && aListed[i] !== undefined) {
                  if (aListed[i].codListedCompany != null && aListed[i].codListedCompany !== undefined && aListed[i].codListedCompany  !== "" ) {
                      if (aListed[i].companyName != null && aListed[i].companyName !== "" ) {
                      //Si existe y se cambia
                      		helper.modifyListed(component, event, helper,aListed[i] );
                      } else {
                      //Si existe y se borra
                            helper.deleteListed(component, event, helper,aListed[i] );
                      }
                  } else {
                     if (aListed[i].companyName != null && aListed[i].companyName !== "" ) {
                      //Si no existe y se crea
                         if (aListed[i].listedCheck === null || aListed[i].companyName === "" || aListed[i].listedCheck === undefined ) {
                             aListed[i].listedCheck  = false;
                         }
                     		helper.createListed(component, event, helper,aListed[i] );
                     }
               }
           }
         }
        }
    },
    createListed : function(component,event,helper,listed){
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

            var externalId = component.get('v.recordId');
            var codUser = component.get('v.codUser');

            if (externalId != null && externalId !=="") {
        		url= url+$A.get("$Label.c.DES_IP_URL_BASE")+ $A.get("$Label.c.DES_IP_URL_OPP_FORM") + externalId + $A.get("$Label.c.DES_IP_COMPANY");
                var jsonOpp = JSON.stringify(listed);
                http.open("POST", url, true);
                http.withCredentials = true;
                http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"), codUser);
                http.setRequestHeader("Content-Type", "application/json");
                http.send(jsonOpp);
            }
        });
    },
    deleteListed : function(component,event,helper,listed){
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

            var externalId = component.get('v.recordId');
            var codUser = component.get('v.codUser');

            if (externalId != null && externalId !=="") {
        		url= url+$A.get("$Label.c.DES_IP_URL_BASE")+ $A.get("$Label.c.DES_IP_URL_OPP_FORM") + externalId + $A.get("$Label.c.DES_IP_COMPANY") + listed.codListedCompany + "?_method=DELETE";

                http.open("POST", url, true);
                http.withCredentials = true;
                http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"), codUser);
                http.setRequestHeader("Content-Type", "application/json");
                http.send(null);
            }
        });
    },
    getCountries: function(component, event, helper) {
    var action = component.get( "c.getCountries" );
         var promise = this.executeAction(component, action);
        return promise.then(
                $A.getCallback(function(result) {
                    component.set( 'v.countries',  JSON.parse(result));
                    helper.showCountryLabel(component, event, helper);
                }),
                $A.getCallback(function(error) {
                  console.error( 'Error calling action "' + action + '" with state: ' + error.message );
                })
        ).catch(function(e){
        });
    },
    showCountryLabel : function (component, event, helper) {
        let action = component.get("c.getCountryLabel");
         action.setParams({
             "formId": component.get("v.recordId")
         });
         action.setCallback(this, function (response) {
             let state = response.getState();
             if (state === "SUCCESS") {
                  component.set('v.formCountry', response.getReturnValue());
             } else {
             }
         });
         $A.enqueueAction(action);
    }
    
})