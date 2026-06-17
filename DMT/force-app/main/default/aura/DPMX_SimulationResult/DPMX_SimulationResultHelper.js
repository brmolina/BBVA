({
	doInit : function(cmp, event, helper) {
		var action = cmp.get('c.getData');
		action.setParams({
			'recordId': cmp.get('v.recordId')
		})
		action.setCallback(this, function(response) {
			var state = response.getState();
			if(state === 'SUCCESS') {
				var result = response.getReturnValue();
				cmp.set('v.dynamicPricing', result.dynamicPricing);
			}else if(state === 'INCOMPLETE'){
				console.log('INCOMPLETE', response);
			}else if(state === 'ERROR') {
				console.log('ERROR', response.getError());
			}
			//helper.doneWaiting(cmp);
		});
		$A.enqueueAction(action);
	},
	handleOnSimulate : function(cmp, event, helper) {

	},
	handleOnSave : function(cmp, event, helper) {
		
	}
})