({
    initComponent: function(cmp, event, helper) {
        cmp.set('v.isVisible', false);
        var recordId = cmp.get('v.recordId');
        var optyId = cmp.get('v.optyId');

         if (optyId === undefined) {
            cmp.set('v.optyId', recordId);
        }
        var actionUser = cmp.get('c.bbvaUserCode');
        var actionRecordType = cmp.get('c.getRecordTypeId');
        actionRecordType.setParams({
            'rtName': $A.get("$Label.c.DES_RT_ACC_Draft_Opportunity")
        })
        var promiseUser = this.executeAction(cmp, actionUser);
        promiseUser.then(
            $A.getCallback(function(result) {
                var parsedResult = result;
                cmp.set('v.codUser', parsedResult);

                helper.fetchData(cmp, event, helper).catch(function(error) {
                })

            }),
            $A.getCallback(function(error) {
            })
        )
        var promiseRecordType = this.executeAction(cmp, actionRecordType);
        promiseRecordType.then(
                $A.getCallback(function(result) {
                    var parsedResult = result;
                    cmp.set('v.recordTypeId', parsedResult);
                }),
                $A.getCallback(function(error) {
                })
            )
    helper.getIsClosed(cmp);
    },


    // Promise Execute action against the server
    executeAction: function(cmp, actionToExecute, callback) {
        return new Promise(function(resolve, reject) {
            actionToExecute.setCallback(this, function(response) {
                var status = response.getState();
                if (status === 'SUCCESS') {
                    resolve(response.getReturnValue());
                } else if (status === 'ERROR') {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            reject(Error('Error messge: ' + errors[0].message));
                        }
                    } else {
                        reject(Error('Unknown error'));
                    }
                }
            });
            $A.enqueueAction(actionToExecute);
        });
    },

    // isVisible: function(cmp, event, helper) {
    //     var action = cmp.get('c.isVisible');
    //     var optyId = cmp.get('v.optyId');

    //     action.setParams({
    //         'oppId': optyId
    //     })
    //     var promise = this.executeAction(cmp, action);

    //     return promise.then(
    //         $A.getCallback(function(result) {
    //             var parsedResult = JSON.parse(result);
    //             if(parsedResult){
    //                //cmp.set('v.isVisible', parsedResult);
    //             }
    //         }),
    //         $A.getCallback(function(error) {
    //         })
    //     ).catch(function(e) {
    //     });
    // },


    fetchData: function(component, event, helper) {
        return new Promise(function(resolve, reject) {
            var httpRequest = new XMLHttpRequest();

            httpRequest.onreadystatechange = $A.getCallback(function() {
              if (this.readyState === 4) { // DONE
                  if (this.status >= 200 && this.status < 300) {
                      helper.parseConfidentialData(component, event, helper, httpRequest);
                      component.set('v.isVisible', true);
                      resolve();
                  } else {
                        component.set('v.isVisible', false);
                      var errorMsg = "";
                      if (this.status === 0) {
                          errorMsg = $A.get("$Label.c.DES_ERROR_IP_SERVER");
                      } else {
                          errorMsg = this.statusText;
                      }
                      reject(errorMsg);
                  }

              }
            });

            helper.callConfidentialData(component, httpRequest);
        });
    },
    showHide : function(component) {
        var editFormVar = component.find("editForm");
        $A.util.toggleClass(editFormVar, "slds-hide");
        var viewFormVar = component.find("viewForm");
        $A.util.toggleClass(viewFormVar, "slds-hide");
    },
    getLabels : function(component, event, helper) {
      var action = component.get( "c.getObjectType" );
      action.setParams({
          "objeto": 'Opportunity'
      });
      var promise = this.executeAction(component, action);
      return promise.then(
              $A.getCallback(function(result) {
                  component.set( 'v.ObjectType', JSON.parse( result));
                  helper.getCountries(component, event, helper);

              }),
              $A.getCallback(function(error) {
                console.error( 'Error calling action "' + action + '" with state: ' + error.message );
              })
      ).catch(function(e){
      });
    },
    showHideIP : function(component) {
      var editFormVar = component.find("editFormIP");
      $A.util.toggleClass(editFormVar, "slds-hide");
      var viewFormVar = component.find("viewFormIP");
      $A.util.toggleClass(viewFormVar, "slds-hide");
    },
    modifyOpp : function(component){
        return new Promise(function(resolve, reject) {
            var httpRequest = new XMLHttpRequest();

            httpRequest.onreadystatechange = $A.getCallback(function() {
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
                        var errorMsg = "";
                        if (this.status === 0) {
                          errorMsg = $A.get("$Label.c.DES_ERROR_IP_SERVER");
                          reject(Error(errorMsg));
                        } else {
                            errorMsg = this.statusText;
                            reject(Error(errorMsg));
                        }

                    }
                }
            });

             var url = component.get('v.endpoint');
              url = url + $A.get("$Label.c.DES_IP_URL_OPP");

            var externalIdVar = component.get('v.recordId');
            var codUser = component.get('v.codUser');
            var opp = component.get('v.opp');


            if (externalIdVar !== null && externalIdVar !== "") {
                url = url + externalIdVar + "?_method=PUT";
                var jsonOpp = JSON.stringify(opp);

                httpRequest.open("POST", url, true);
                httpRequest.withCredentials = true;
                httpRequest.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"), codUser);
                httpRequest.setRequestHeader("Content-Type", "application/json");
                httpRequest.send(jsonOpp);
            }
        });
    },
    showCountryLabel : function (component, event, helper) {
        var opp = component.get("v.opp");
        var countriesValues = "";
         var values;
        var objectType = component.get('v.ObjectType');
        var options = objectType.Opportunity.DES_Booking_Geography__c.picklistOptions;


        if(opp.bbvaCountriesParticipants != null && opp.bbvaCountriesParticipants !==""){
            values = opp.bbvaCountriesParticipants.split(";");
            for(var i = 0; i < values.length; i++){
                var pais = options.filter(function (pais) { return pais.value === values[i] });
                if(pais !== undefined){
                    countriesValues += pais[0].label;
                    if(i+1 < values.length){
                        countriesValues +=";";
                    }
                }
           }
        }
        component.set("v.countriesValues", countriesValues);

        component.set("v.defaultOptionsCountry", values);

    },
    showBookingLabel : function (component, event, helper) {
        var opp = component.get("v.opp");
        var bookingValues = "";
        var objectType = component.get('v.ObjectType');
         var options = objectType.Opportunity.DES_Booking_Geography__c.picklistOptions;

        if(opp.bookingGeography != null && opp.bookingGeography !== ""){
             var pais = options.filter(function (pais) { return pais.value === opp.bookingGeography });
      bookingValues = pais[0].label;
        }

        component.set("v.bookingValues", bookingValues);


        component.set("v.defaultOptionsBooking", opp.bookingGeography)
    },
    getCountries: function(component, event, helper) {
    var action = component.get( "c.getCountries" );
         var promise = this.executeAction(component, action);
        return promise.then(
                $A.getCallback(function(result) {
                    component.set( 'v.countries',  JSON.parse(result));
                    helper.showCountryLabel(component, event, helper);
                    helper.showBookingLabel(component, event, helper);
                }),
                $A.getCallback(function(error) {
                  console.error( 'Error calling action "' + action + '" with state: ' + error.message );
                })
        ).catch(function(e){
        });
    },
    parseConfidentialData: function(component,event,helper, http ){
      var response = JSON.parse(http.responseText);
      if (response !== null && response !== "") {
          component.set("v.opp", response);
          helper.getLabels(component,event,helper).catch(function(e) {
          });

      }
    },
    callConfidentialData: function(component, http){
      var urlEndPoint = component.get('v.endpoint');
      urlEndPoint = urlEndPoint + $A.get("$Label.c.DES_IP_URL_OPP");

      var externalId = component.get('v.recordId');
      var codUser = component.get('v.codUser');
      if (externalId !== null && externalId !== "") {
        urlEndPoint= urlEndPoint + externalId;
        http.open("GET", urlEndPoint, true);
        http.withCredentials = true;
        http.setRequestHeader("Content-Type", "application/json");
        http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"), codUser);
        http.send(null);
      }
    },
    getIsClosed : function(component ) {
      var actionCld = component.get( "c.isOppClosed" );
      var oppId = component.get('v.optyId');

        actionCld.setParams({
            'oppId': oppId
        })

      var promiseCld = this.executeAction(component, actionCld);
      return promiseCld.then(
              $A.getCallback(function(result) {
                  component.set( 'v.isClosed',  result);
              }),
              $A.getCallback(function(error) {
                console.error( 'Error calling action "' + action + '" with state: ' + error.message );
              })
      ).catch(function(e){
      });
    },
    getUrlIp : function(component ) {
      var actionUrl = component.get( "c.urlIpServices" );

      var promiseUrl = this.executeAction(component, actionUrl);
      return promiseUrl.then(
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