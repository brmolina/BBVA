({
	doInit : function(cmp, event, helper) {
		helper.waiting(cmp);
		var action = cmp.get('c.initialData');
		action.setParams({
			'RPPCalculatorSimulationId': cmp.get('v.RPPCalculatorSimulationId')
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if(state === 'SUCCESS') {
				var result = response.getReturnValue();
				cmp.set("v.RPPCalculatorSimulation", result.RPPCalculatorSimulation);
				cmp.set("v.RPPCalculatorSimulationOld", result.RPPCalculatorSimulation);
				cmp.set("v.RPPCalculatorSimDebtors", result.RPPCalculatorSimDebtors);
				cmp.set("v.RPPCalculatorSimFields", result.RPPCalculatorSimFields);
				cmp.set("v.RPPCalculatorSimDebtorFields", result.RPPCalculatorSimDebtorFields);
				cmp.set("v.RPPCalculatorSimDebtorsMap", result.RPPCalculatorSimDebtorsMap);
				cmp.set("v.internalRatingSimPicklist", result.internalRatingSimPicklist);
				cmp.set("v.externalRatingSimPicklist", result.externalRatingSimPicklist);
				cmp.set("v.internalRatingDebtorPicklist", result.internalRatingDebtorPicklist);
				cmp.set("v.externalRatingDebtorPicklist", result.externalRatingDebtorPicklist);
			}else if(state === 'INCOMPLETE'){
				console.log('INCOMPLETE', response);
				helper.showToast('error', 'Error', $A.get('$Label.c.RPP_Generic_Error'));
			}else if(state === 'ERROR') {
				console.log('ERROR', response.getError());
				var errors = response.getError();
				if (errors) {
					if(errors[0] && errors[0].message) {
						helper.showToast('error', 'Error', response.getError()[0].message);
					}else{
						helper.showToast('error', 'Error', $A.get('$Label.c.RPP_Generic_Error'));
					}
				}
			}
			helper.doneWaiting(cmp);
		});
		$A.enqueueAction(action);
	},
	handleOnSave : function(cmp, event, helper) {
		helper.waiting(cmp);
		var action = cmp.get('c.modifyData');
		action.setParams({
			'RPPCalculatorSimulation': cmp.get('v.RPPCalculatorSimulation'),
			'RPPCalculatorSimDebtors': cmp.get('v.RPPCalculatorSimDebtors'),
			'RPPCalculatorSimDebtorsMap': cmp.get('v.RPPCalculatorSimDebtorsMap')
		})
		action.setCallback(this, function(response) {
			var state = response.getState();
			if(state === 'SUCCESS') {
				var result = response.getReturnValue();
				if(result.success) {
					helper.showToast('success', '', $A.get('$Label.c.RPP_Information_Updated_Correctly'));
					//Refresh Simulator evt
					let appEvent = $A.get('e.c:RPP_CalculatorRefresh_evt');
					appEvent.setParams({
						'recordId': cmp.get('v.RPPCalculatorSimulation.Source_RPP_Calculator__c')
					});
					appEvent.fire();
					helper.destroyCmp(cmp, event, helper);
				}else{
					helper.showToast('Error', 'Error', $A.get('$Label.c.RPP_No_Information_Has_Been_Modified'));
				}
			}else if(state === 'INCOMPLETE'){
				console.log('INCOMPLETE', response);
				helper.showToast('error', 'Error', $A.get('$Label.c.RPP_Generic_Error'));
			}else if(state === 'ERROR') {
				console.log('ERROR', response.getError());
				helper.showToast('error', 'Error', response.getError()[0].message);
			}
			helper.doneWaiting(cmp);
		});
		$A.enqueueAction(action);
	},
	showToast: function(type, title, message) {
		var toastEvent = $A.get('e.force:showToast');
		toastEvent.setParams({
			title: title,
			message: message,
			duration: 5000,
			key: 'info_alt',
			type: type,
			mode: 'dismissible'
		});
		toastEvent.fire();
	},
	waiting: function(cmp) {
		cmp.set('v.waiting', true);
	},
	doneWaiting: function(cmp) {
		cmp.set('v.waiting', false);
	}
})