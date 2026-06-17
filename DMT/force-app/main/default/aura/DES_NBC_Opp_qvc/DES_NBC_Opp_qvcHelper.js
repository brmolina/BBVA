({

	getJson : function(component ) {
		var actionOpp = component.get( "c.opportunityJson" );
		actionOpp.setParams({
            'nbcId': component.get('v.recordId')
        })
		var promiseUrl = this.executeAction(component, actionOpp);
		return promiseUrl.then(
				$A.getCallback(function(result) {
					component.set( 'v.inputJson',  JSON.parse(result));
				}),
				$A.getCallback(function(error) {
				  console.error( 'Error calling action getUrlIp with state: ' + error.message );
				})
		).catch(function(e){
		});
	},
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
    }
})