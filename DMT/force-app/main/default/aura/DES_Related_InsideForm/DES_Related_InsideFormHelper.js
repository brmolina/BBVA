({
    /*isVisible : function(component, event,valObject) {
        var actionTopicVisible = component.get("c.isVisible2");
        actionTopicVisible.setParams({
            'oppId': component.get('v.recordId'),
            'valObject':valObject,
        })

        var promiseVisible = this.executeAction(component, actionTopicVisible);
        return promiseVisible.then(
            $A.getCallback(function(result) {
                component.set('{!v.isVisible}', result);
            }),
            $A.getCallback(function(error) {
            })
        ).catch(function(e) {
        });
    },*/
    fetchTopicsOpp : function(component, event,valObject) {
        var actionTopicsOpp = component.get("c.oppForms2");
        actionTopicsOpp.setParams({
            'oppId': component.get('v.recordId'),
            'valObject':valObject,
        })
        var promise = this.executeAction(component, actionTopicsOpp);
        return promise.then(
            $A.getCallback(function(result) {
                var parsedResult = JSON.parse(result);
                if(parsedResult){
                    component.set('v.IpForms', parsedResult);
                    component.set('v.sizeIpForms', parsedResult.length);
                }
            }),
            $A.getCallback(function(error) {
            })
        ).catch(function(e) {
        });
    },
    executeAction: function(component, executedactionTopics, callback) {
        return new Promise(function(resolve, reject) {
            executedactionTopics.setCallback(this, function(response) {
                var statusactionTopics = response.getState();
                if (statusactionTopics === 'SUCCESS') {
                    resolve(response.getReturnValue());
                } else if (statusactionTopics === 'ERROR') {
                    var errorTopics = response.getError();
                    if (errorTopics) {
                        if (errorTopics[0] && errorTopics[0].message) {
                            reject(
                                Error('Err: ' + errorTopics[0].message)
                            );
                        }
                    } else {
                        reject(
                            Error('Uknown error')
                        );
                    }
                }
            });
            $A.enqueueAction(executedactionTopics);
        });
    },
    fetchTopicsCurrentUser : function(component, event) {
        var actionTopicCurrentUser = component.get("c.bbvaUserCode");

        var promise = this.executeAction(component, actionTopicCurrentUser);
        return promise.then(
            $A.getCallback(function(result) {
                component.set('{!v.currentUser}', result);
            }),
            $A.getCallback(function(error) {
            })
        ).catch(function(e) {
        });
    },
    getUrlIpOppVT : function(component ) {
      var actionUrlVT = component.get( "c.urlIpServices" );

      var promiseUrlVT = this.executeAction(component, actionUrlVT);
      return promiseUrlVT.then(
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