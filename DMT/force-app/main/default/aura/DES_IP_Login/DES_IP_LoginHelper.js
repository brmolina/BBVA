({
  executeAction : function(component, action, callback) {
    // Promise Execute action against the server
    return new Promise(function(resolve, reject) {
      action.setCallback(this,
          function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
              resolve(response.getReturnValue());
            } else if (state === 'ERROR') {
              var errors = response.getError();
              if (errors) {
                if (errors[0] && errors[0].message) {
                  reject(Error('Error message: '
                      + errors[0].message));
                }
              } else {
                reject(Error('Unknown error'));
              }
            }
          });
      $A.enqueueAction(action);
    });
  },
   getUrlIp : function(component ) {
      var actionUrl = component.get( "c.urlIpServices" );

      var promiseUrl = this.executeAction(component, actionUrl);
      return promiseUrl.then(
              $A.getCallback(function(result) {
                  component.set( 'v.endpoint',  result.toLowerCase());
              }),
              $A.getCallback(function(error) {
                console.error( 'Error calling action getUrlIp with state: ' + error.message );
              })
      ).catch(function(e){
      });
    }
})