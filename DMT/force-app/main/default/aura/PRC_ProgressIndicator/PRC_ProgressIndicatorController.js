({
	doinit: function (component, event, helper) {
		console.log('Class: PRC_ProgressIndicatorController.js > Method: doinit > LOADING...');
		console.log('Class: PRC_ProgressIndicatorController.js > Method: doinit > entro en el init sin más');
		console.log('Class: PRC_ProgressIndicatorController.js > Method: doinit > currentstep: ' + component.get('v.currentstep'));
		helper.loadprogressindicator(component, event, helper);
	}
})