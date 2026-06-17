({
    isVisible: function(component, event) {
      var actionVisibleInsideInfo = component.get('c.isVisible');
      actionVisibleInsideInfo.setParams({
            'visitId': component.get('v.recordId')
        })

      var promiseVisibleInside = this.executeAction(component, actionVisibleInsideInfo);
      return promiseVisibleInside.then(
            $A.getCallback(function(result) {
                var parsedResult = result;
                component.set('{!v.isVisible}', parsedResult);
            }),
            $A.getCallback(function(error) {
            })
        ).catch(function(e) {
        });
    },
    fetchCurrentUser: function(component, event) {
        var action = component.get('c.bbvaUserCode');

        var promise = this.executeAction(component, action);
        return promise.then(
            $A.getCallback(function(result) {
                var parsedResult = result;
                if(parsedResult) {
                    component.set('{!v.currentUser}', parsedResult);
                }
            }),
            $A.getCallback(function(error) {
            })
        ).catch(function(e) {
        });
    },
  fetchVisitTopics: function(component, event, helper) {
        var action = component.get('c.visitTopics');
        action.setParams({
            'visitId': component.get('v.recordId')
        });

        var promise = this.executeAction(component, action);
        return promise.then(
            $A.getCallback(function(result) {
                var parsedResult = JSON.parse(result);
                if(parsedResult) {
                    component.set('v.topics', parsedResult);
                    component.set('v.sizeTopics', parsedResult.length);
                  if(parsedResult.length > 0) {
                    helper.visitDescriptions(component, event, helper).catch(function(e) {
              });
                  }
                }
            }),
            $A.getCallback(function(error) {
            })
        ).catch(function(e) {
        });
    },
    selectOperation: function(component, url, http, codVisitTopic) {
        var codOwner = component.get('v.currentUser');
        var codVisit = component.get('v.recordId');

        url = url + $A.get('$Label.c.DES_IP_URL_VISIT') + codVisit + $A.get('$Label.c.DES_IP_URL_VISIT_TOPICS') + codVisitTopic + "?_method=DELETE";
        http.open('POST', url, true);
        http.withCredentials = true;
        http.setRequestHeader('Content-Type', 'application/json');
        http.setRequestHeader($A.get('$Label.c.DES_IP_HEADER_USER'),
                              codOwner);
        http.send(null);
    },
    deleteSf: function(component, event, helper, codVisitTopic) {
        var action = component.get('c.delVisitTopic');
        action.setParams({
            'codVisitTopic': codVisitTopic
        });

        var promise = this.executeAction(component, action);
        return promise.then(
            $A.getCallback(function(result) {
              helper.fetchVisitTopics(component, event, helper);
            }),
            $A.getCallback(function(error) {
            })
        ).catch(function(e) {
        });
    },
  visitDescriptions: function(component, event, helper) {
    return new Promise(
      function(resolve, reject) {
        var http4 = new XMLHttpRequest();
        var url4 = component.get( 'v.endpoint');
        http4.onreadystatechange = $A.getCallback(function() {
              if (this.readyState === 4) {
                if (this.status >= 200 && this.status < 300) {
                  var resp  = JSON.parse(http4.responseText);
                  helper.getAllTopics(component, resp);
                  resolve();
                } else {
                  var errtext = "";
                  if (this.status === 0) {
                    errtext = $A.get("$Label.c.DES_ERROR_IP_SERVER");
                  } else {
                    errtext = this.statusText;
                  }
                  reject(
                      new Error(errtext)
                  );
                }
              }
            });
            var codOwner = component.get('v.currentUser');
            var codVisit = component.get('v.recordId');

            url4 = url4 + $A.get("$Label.c.DES_IP_URL_VISIT") + codVisit + $A.get("$Label.c.DES_IP_URL_VISIT_TOPICS");
            http4.open("GET", url4, true);
            http4.withCredentials = true;
            http4.setRequestHeader("Content-Type", "application/json");
            http4.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"),
                                codOwner);
            http4.send(null);

      });

  },
  getAllTopics: function(component, resp) {
    var topicsMap = [];
    var topicsWithDesc = [];
    resp.forEach(function(element) {
      topicsMap[element.codVisitTopic] = element.visitTopicDescription;
    });
    component.get("v.topics").forEach(function(element) {
      element.dwp_kitv__topic_desc__c = topicsMap[element.Id];
      topicsWithDesc.push(element);
    });
    component.set("v.topics", topicsWithDesc);
  },
    executeAction: function(component, act1, callback) {
        return new Promise(function(resolve, reject) {
            act1.setCallback(this, function(response) {
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
            $A.enqueueAction(act1);
        });
    },
    showSpinner: function(component, helper) {
      component.set('v.Spinner', true);
  },

  deleteRecord: function (component, event, helper, codVisitTopic) {
    helper.showSpinner(component, helper);
  helper.checkClosedVT(component, event, helper).then(
          $A.getCallback(function(result) {
              var isClosed = component.get("v.isClosed");
              if(isClosed !== true){
                  helper.deleteVT(component, event, helper,codVisitTopic);
              }

          }),
          $A.getCallback(function(error) {
              console.error( 'Error calling action "' + action + '" with state: ' + error.message );
          }));
  },
  editRecord: function(component, event, helper, codVisitTopic, descVisitTopic, opportunityName) {
    helper.runEditTopicFlow(component, event, helper, codVisitTopic, descVisitTopic, opportunityName);
  },
  runEditTopicFlow: function (component, event, helper, visitTopicId, descVisitTopic, opportunityName) {
      component.set("v.isOpen", true);
      var flow = component.find("New_Visit_Topic");
      var inputVariables = [
          {
            name: "recordId",
            type: "String",
            value: component.get("v.recordId")
          },
          {
            name: "var_topicId",
            type: "String",
            value: visitTopicId
          },
          {
            name: "var_descriptionVal",
            type: "String",
            value: descVisitTopic
          },
          {
            name: "var_oppName",
            type: "String",
            value: opportunityName
          }
      ];
      flow.startFlow("New_Visit_Topic", inputVariables);
  },
    checkClosedVT: function(component, event, helper) {
        var actionVT = component.get("c.isVisitClosed");
        actionVT.setParams({
            'codVisit': component.get('v.recordId')
        })
        var promiseVT = this.executeAction(component, actionVT);
          return promiseVT.then(
                  $A.getCallback(function(result) {
                      component.set( 'v.isClosed',  result);
                  }),
                  $A.getCallback(function(error) {
                    console.error( 'Error calling action "' + actionVT + '" with state: ' + error.message );
                  })
          ).catch(function(e){
          });
    },
    deleteVT: function(component, event, helper,codVisitTopic) {
        return new Promise(
          function(resolve, reject) {
            var http = new XMLHttpRequest();
            var url = component.get( 'v.endpoint');
            http.onreadystatechange = $A
            .getCallback(function() {
                if (this.readyState === 4) {
                  if (this.status >= 200 && this.status < 300) {
                    helper.deleteSf(component, event, helper, codVisitTopic);
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
            helper.selectOperation(component, url, http, codVisitTopic);
          });
    },
    getUrlIpOppT : function(component ) {
      var actionUrlT = component.get( "c.urlIpServices" );

      var promiseUrlT = this.executeAction(component, actionUrlT);
      return promiseUrlT.then(
              $A.getCallback(function(result) {
                  component.set( 'v.endpoint',  result);
              }),
              $A.getCallback(function(error) {
                console.error( 'Error calling action getUrlIp with state: ' + error.message );
              })
      ).catch(function(e){
      });
    }
});