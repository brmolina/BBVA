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
	handleAddClientInformation : function(cmp, event, helper) {
		let attr = {
			'acquirerActivityWrapper': cmp.get('v.acquirerActivityWrapper'),
			'action': 'add',
			'dynamicPricing': cmp.get('v.dynamicPricing'),
		};
		helper.loadComponent(cmp, event, helper, 'DPMX_SimulatorClientInfo', attr).then($A.getCallback(newComponent => {
			let body = [];
			body.push(newComponent);
			cmp.set('v.body', body);
		}));
	},
	handleModifyClientInformation : function(cmp, event, helper) {
		let attr = {
			'acquirerActivityWrapper': cmp.get('v.acquirerActivityWrapper'),
			'action': 'edit',
			'dynamicPricing': cmp.get('v.dynamicPricing')
		};
		helper.loadComponent(cmp, event, helper, 'DPMX_SimulatorClientInfo', attr).then($A.getCallback(newComponent => {
			let body = [];
			body.push(newComponent);
			cmp.set('v.body', body);
		}));
	},
	handleAddDevices : function(cmp, event, helper) {
		let attr = {
			'acquirerActivityWrapper': cmp.get('v.acquirerActivityWrapper'),
			'action': 'add',
			'dynamicPricing': cmp.get('v.dynamicPricing'),
		};
		helper.loadComponent(cmp, event, helper, 'DPMX_SimulatorDevices', attr).then($A.getCallback(newComponent => {
			let body = [];
			body.push(newComponent);
			cmp.set('v.body', body);
		}));
	},
	handleModifyDevices : function(cmp, event, helper) {
		let attr = {
			'acquirerActivityWrapper': cmp.get('v.acquirerActivityWrapper'),
			'action': 'edit',
			'dynamicPricing': cmp.get('v.dynamicPricing')
		};
		helper.loadComponent(cmp, event, helper, 'DPMX_SimulatorDevices', attr).then($A.getCallback(newComponent => {
			let body = [];
			body.push(newComponent);
			cmp.set('v.body', body);
		}));
	},
	loadComponent: function(cmp, event, helper, cmpName, cmpAttr) {
		return new Promise($A.getCallback(function(resolve, reject) {
		  $A.createComponent(
			'c:' + cmpName, cmpAttr, function(newCmp, status, errorMessage) {
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
	  }
})