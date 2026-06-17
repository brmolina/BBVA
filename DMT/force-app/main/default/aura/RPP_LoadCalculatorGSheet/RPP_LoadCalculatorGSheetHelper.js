({
	doInit : function(cmp, event, helper) {
		helper.waiting(cmp);
		var action = cmp.get('c.initialData');
		action.setCallback(this, function(response) {
			var state = response.getState();
			if(state === 'SUCCESS') {
				var result = response.getReturnValue();
				cmp.set("v.hasPermission", result.hasPermission);
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
	loadGSheet : function(cmp, event, helper) {
		helper.waiting(cmp);
		var action = cmp.get('c.loadGSheetData');
		action.setCallback(this, function(response) {
			var state = response.getState();
			if(state === 'SUCCESS') {
				var result = response.getReturnValue();
				if (result.success) {
					console.log('SUCCESS', response);
					helper.showToast('success',  $A.get('$Label.c.RPP_Load_Request_Sent'),  $A.get('$Label.c.RPP_Load_Request_Sent_Info'));
				}else {
					helper.showToast('Error', 'Error', result.errorMessage);
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