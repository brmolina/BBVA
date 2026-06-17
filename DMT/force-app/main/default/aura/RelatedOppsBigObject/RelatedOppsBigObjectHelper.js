({
	fetchOppsVisits : function(component, event) {
	  var actionOpps = component.get("c.gtOpps");
	  actionOpps.setParams({
		  'accountId': component.get('v.accountId'),
		  'visitId': component.get('v.visitId')
	  })
	  var promise = this.executeActionOpps(component, actionOpps);
	  return promise.then(
		  $A.getCallback(function(result) {
			  var parsedResult = JSON.parse(result);
			  if(parsedResult){
				  component.set('v.opps', parsedResult);
				  component.set('v.sizeOpps', parsedResult.length);
			  }
		  }),
		  $A.getCallback(function(error) {
		  })
	  ).catch(function(e) {
	  });
	},
	// Promise Execute action against the server
	executeActionOpps: function (component, promiseAct, callback) {
	  return new Promise(function (resolve, reject) {
		promiseAct.setCallback(this, function (response) {
		  var statusactionopps = response.getState();
		  if (statusactionopps === 'SUCCESS') {
			  resolve(response.getReturnValue());
		  } else if (statusactionopps === 'ERROR') {
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
	},
	navigateRecord: function(component, event, helper, accountId, oppId) {
	  var pageReference = {
		  type: 'standard__component',
		  attributes: {
		  	componentName: 'c__HistoricOppAccount',
		  },
		  state: {
		  	"c__accountId": accountId,
		  	"c__oppId": oppId
		  }
	  };
	  var navService = component.find("navService");
	  event.preventDefault();
	  navService.navigate(pageReference);
	},
  navigateOpp: function(component, event, helper, oppId) {
    var pageReference = {
      type: 'standard__recordPage',
      attributes: {
        actionName: 'view',
        objectApiName: 'Opportunity',
        recordId : oppId
      },
    };
    var navService = component.find("navService");
    event.preventDefault();
    navService.navigate(pageReference);
  }
})