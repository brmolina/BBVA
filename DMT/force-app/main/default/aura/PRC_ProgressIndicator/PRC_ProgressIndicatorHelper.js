({
	loadprogressindicator: function (component, event, helper) {
		var container = component.find('container');
		var containerbody = container.get('v.body');
		var currentstep = component.get('v.currentstep');
		$A.createComponents(
			[
				['lightning:progressStep', { label: '1', value: '1' }],
				['lightning:progressStep', { label: '1', value: '2' }],
				['lightning:progressStep', { label: '1', value: '3' }]
			],
			function (steps) {
				$A.createComponent(
					'lightning:progressIndicator',
					{
						currentstep: currentstep,
						body: [].push(steps)
					},
					function (indicator) {
						containerbody = [];
						containerbody.push(indicator);
						container.set('v.body', containerbody);
						component.set('v.refresh', true);
						console.log('refresh');
					}
				);
			}
		);
	}
})