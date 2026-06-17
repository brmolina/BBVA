({
  fetchProductsOpp : function(component, event) {
    var actionProducts = component.get("c.getProducts");
    actionProducts.setParams({
        'oppId': component.get('v.oppId')
    })
    var promise = this.executeAction1(component, actionProducts);
    return promise.then(
        $A.getCallback(function(result) {
            var parsedResult = JSON.parse(result);
            if(parsedResult){
                component.set('v.products', parsedResult);
                component.set('v.sizeProducts', parsedResult.length);
            }
        }),
        $A.getCallback(function(error) {
        })
    ).catch(function(e) {
    });
  },
  // Promise Execute action against the server
  executeAction1: function (component, promiseAct, callback) {
    return new Promise(function (resolve, reject) {
      promiseAct.setCallback(this, function (response) {
        var statusaction1 = response.getState();
        if (statusaction1 === 'SUCCESS') {
          resolve(response.getReturnValue());
        } else if (statusaction1 === 'ERROR') {
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
      $A.enqueueAction(promiseAct);
    });
  }
})