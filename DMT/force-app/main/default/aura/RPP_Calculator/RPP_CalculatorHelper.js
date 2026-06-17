({
	doInit : function(cmp, event, helper) {
		helper.waiting(cmp);
		var action = cmp.get('c.initialData');
		action.setParams({
			'recordId': cmp.get('v.recordId'),
			'selectedSimulation': cmp.get('v.selectedSimulation')
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if(state === 'SUCCESS') {
				var result = response.getReturnValue();
				cmp.set("v.RPPCalculator", result.RPPCalculator);
				cmp.set("v.RPPCalculatorFields", result.RPPCalculatorFields);
				if (!result.success) {
					cmp.set("v.hasErrors", true);
					cmp.set("v.errorsList", result.errorsList);
				} else {
					if (result.refresh) {
						let appEvent = $A.get('e.c:RPP_CalculatorRefresh_evt');
						appEvent.setParams({
							'recordId': cmp.get('v.recordId')
						});
						appEvent.fire();
					} else {
						cmp.set("v.RPPCalculatorDebtors", result.RPPCalculatorDebtors);
						cmp.set("v.RPPCalculatorDebtorFields", result.RPPCalculatorDebtorFields);
						cmp.set("v.simulationsWrapperList", result.simulationsWrapperList);
						cmp.set("v.selectedSimulation", result.selectedSimulation);
						cmp.set("v.hasSimulations", result.hasSimulations);
						cmp.set("v.canSimulate", result.canSimulate);
						cmp.set("v.showSimulationResults", result.showSimulationResults);
						cmp.set("v.showSimulationButtons", result.showSimulationButtons);
						cmp.set("v.hasPermission", result.hasPermission);
						cmp.set("v.isGoal1", result.isGoal1);
						cmp.set("v.RPPCalculatorSimulation", result.RPPCalculatorSimulation);
						cmp.set("v.RPPCalculatorSimFields", result.RPPCalculatorSimFields);
						cmp.set("v.RPPCalculatorSimulationDebtors", result.RPPCalculatorSimulationDebtors);
						cmp.set("v.RPPCalculatorSimDebtorFields", result.RPPCalculatorSimDebtorFields);
					}
				}
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
	handleOnGetRatings : function(cmp, event, helper) {
		helper.waiting(cmp);
		var action = cmp.get('c.getRatings');
		action.setParams({
			'id': cmp.get('v.RPPCalculator.Id')
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if(state === 'SUCCESS') {
				var result = response.getReturnValue();
				if (result.success) {
					// refrescar
					cmp.set("v.selectedTab", 'simulations');
					cmp.set("v.selectedSimulation", result.selectedSimulation);
					helper.showToast('success', '', $A.get('$Label.c.RPP_Ratings_Obtained'));
					let appEvent = $A.get('e.c:RPP_CalculatorRefresh_evt');
					appEvent.setParams({
						'recordId': cmp.get('v.recordId')
					});
                	appEvent.fire();
				}else {
					helper.showToast('error', 'Error', result.errorMessage);
				}
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
	handleOnSimulate : function(cmp, event, helper) {
		helper.waiting(cmp);
		var action = cmp.get('c.getFinalData');
		action.setParams({
			'id': cmp.get('v.RPPCalculatorSimulation.Id')
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if(state === 'SUCCESS') {
				var result = response.getReturnValue();
				if (result.success) {
					// refrescar
					helper.showToast('success', '', $A.get('$Label.c.RPP_Simulation_Completed_Successfully'));
					let appEvent = $A.get('e.c:RPP_CalculatorRefresh_evt');
					appEvent.setParams({
						'recordId': cmp.get('v.recordId')
					});
                appEvent.fire();
				}else {
					helper.showToast('error', 'Error', result.errorMessage);
				}
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
	handleOnGetSimulationData : function(cmp, event, helper) {
		helper.waiting(cmp);
		var action = cmp.get('c.getSimulationData');
		action.setParams({
			'id': cmp.find("selectedOption").get("v.value")
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if(state === 'SUCCESS') {
				var result = response.getReturnValue();
				cmp.set("v.RPPCalculatorSimulation", result.RPPCalculatorSimulation);
				cmp.set("v.RPPCalculatorSimulationDebtors", result.RPPCalculatorSimulationDebtors);
				cmp.set("v.canSimulate", result.canSimulate);
				cmp.set("v.showSimulationResults", result.showSimulationResults);
				cmp.set("v.selectedSimTab", 'rppport');
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
	handleOnSetFinalSimulation : function(cmp, event, helper) {
		helper.waiting(cmp);
		var action = cmp.get('c.setFinalSimulation');
		action.setParams({
			'id': cmp.get('v.RPPCalculatorSimulation.Id'),
			'name': cmp.get('v.RPPCalculatorSimulation.Name'),
			'RPPCalculatorId': cmp.get('v.recordId')
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if(state === 'SUCCESS') {
				var result = response.getReturnValue();
				if (result.success) {
					cmp.set("v.showSimulationButtons", result.showSimulationButtons);
					helper.showToast('success', 'OK', $A.get('$Label.c.RPP_Simulation_Selected_As_Final'));
					let appEvent = $A.get('e.c:RPP_CalculatorRefresh_evt');
					appEvent.setParams({
						'recordId': cmp.get('v.recordId')
					});
            	    appEvent.fire();
				}else {
					helper.showToast('Error', 'Error', $A.get('$Label.c.RPP_Select_As_Final_Simulation_Error'));
				}
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
	handleOnModifyData : function(cmp, event, helper) {
		let attr = {
			'RPPCalculatorSimulationId': cmp.get('v.RPPCalculatorSimulation.Id')
        };
		helper.loadComponent(cmp, event, helper, 'RPP_CalculatorModify', attr).then($A.getCallback(newComponent => {
            let body = [];
            body.push(newComponent);
            cmp.set('v.body', body);
        }));
	},
	loadComponent: function(cmp, event, helper, cmpName, cmpAttr) {
        return new Promise($A.getCallback(function(resolve, reject) {
            $A.createComponent(
                'c:' + cmpName, cmpAttr,
                function(newCmp, status, errorMessage) {
                    if (status === 'SUCCESS') {
                        resolve(newCmp);
                    } else if (status === 'INCOMPLETE' || status === 'ERROR') {
                        helper.showToast('Error', 'error', errorMessage);
                    }
                }
            );
        }));
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