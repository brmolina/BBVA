({
	doinit: function (component, event, helper) {
		var idrecord = component.get('v.inputAttributes').recordId;
		component.set('v.recordId', idrecord);
		helper.displaymodal(component, event, helper, true);
		var stateloaded = helper.getstate(component, event, helper);
		stateloaded.then($A.getCallback(function (resolve) {
			var state = component.get('v.currentstep');
			console.log('state: ' + state);
			var cmpconfig = helper.selectcomponent(idrecord, state);
			let cmpname = cmpconfig.get('cmpname');
			let params = cmpconfig.get('params');
			var componentloaded = helper.loadcomponent(component, event, helper, cmpname, params);
			componentloaded.then(function (resolve) {
				component.set('v.showspinner', false);
				console.log('component loaded!');
				helper.loadbuttons(component, event, helper, state);
				helper.loadprogressindicator(component);
			}).catch(function (error) {
				console.log('component not loaded!');
			});
		}));
	},
    pickError: function (component, event, helper) {
        //ver codeerror =event.getParam("codeserror");
        //event.getParam("codesstatus");

		helper.showToast(component, event, helper, 'error', event.getParam("codeserror"));
	},
	closemodal: function (component, event, helper) {
		console.log('cierro el modal');
		var closemodalparam = event.getParam('closemodalbool');
		if(!closemodalparam) {
		  helper.displaymodal(component, event, helper, false);
		}
	},
	closemodalevt: function (component, event, helper) {
		var loadcmpevt = component.getEvent('closemodalevt');
		console.log('recupero el evento:' + loadcmpevt);
		loadcmpevt.fire();
		console.log('lanzo el evento');
	},
	continue: function (component, event, helper) {
		let formcomponentcontainer = component.find('modalbody');
		let body = formcomponentcontainer.get('v.body')[0];
		if (helper.validFormSelector(body)) {
			let selectorcontainer = component.find('modalbody');
			console.log('fcc: ' + selectorcontainer);
			console.log('fc body: ' + selectorcontainer.get('v.body')[0]);
			let selectorcmp = selectorcontainer.get('v.body')[0];
			console.log('selectorcmp selectorcmp: ' + selectorcmp);
			selectorcmp.saveproduct();
			component.set('v.currentstep', 'Price Form');
		}
	},
	save: function (component, event, helper) {
		let formcomponentcontainer = component.find('modalbody');
		console.log('>>>>>> fcc: ' + formcomponentcontainer);
		console.log('>>>>>> fc body: ' + formcomponentcontainer.get('v.body')[0]);
		let formcomponent = formcomponentcontainer.get('v.body')[0].find('priceform');
		var amortization = formcomponentcontainer.get('v.body')[0].find('amortizationTypeId').get('v.value');
		console.log('>>>>>> formcomponent: ' + formcomponent);
		component.set('v.msgToast', 'save');
		formcomponent.submit();
		if (amortization !== 'USER_DEFINED') {
			helper.deleteAmortizationData(component, event, helper);
		}
		component.set('v.lastaction', 'save');
		var refreshDetailEvt = $A.get("e.c:PRC_RefreshDetailsEvt");
		refreshDetailEvt.fire();
	},
	calculate: function (component, event, helper) {
		let formcomponentcontainer = component.find('modalbody');
		console.log('fcc: ' + formcomponentcontainer);
		console.log('fc body: ' + formcomponentcontainer.get('v.body')[0]);
		let body = formcomponentcontainer.get('v.body')[0];
		var formcomponent = formcomponentcontainer.get('v.body')[0].find('priceform');
		component.set('v.msgToast', 'calculate');//????

		//Solo realizamos el envio del formulario si comprobamos primero que los datos seleccionados son correctos
		//Si no, en el propio validForm se genera un mensaje de error
		if (helper.validForm (body)) {
			formcomponent.submit();
		}
	},
	chooseprice: function (component, event, helper) {
		let formcomponentcontainer = component.find('modalbody');
		console.log('>>>>> fcc: ' + formcomponentcontainer);
		console.log('>>>>> fc body: ' + formcomponentcontainer.get('v.body')[0]);
		let formcomponent = formcomponentcontainer.get('v.body')[0];
		console.log('>>>>> formcomponent formcomponent: ' + formcomponent);
		formcomponent.savePrice();
	},
	loadcmp: function (component, event, helper) {
		console.log('>>>>>>>> loadcomponent del product handler');
		var cmpname = event.getParam('componentname');
		var params = event.getParam('params');
		var cmploaded = helper.loadcomponent(component, event, helper, cmpname, params);
		cmploaded.then($A.getCallback(function (resolve) {
			var step = component.get('v.currentstep');
			helper.loadbuttons(component, event, helper, step);
			helper.loadprogressindicator(component);
		}));
	},
	loadcmpevt: function (component, event, helper) {
		var loadcmpevt = component.getEvent('loadcomponentevt');
		console.log('recupero el evento:' + loadcmpevt);
		var params = {
			'componentname': 'c:PRC_PriceForm',
			'params': {
				'aura:id': 'Price Form',
				'recordId': component.get('v.recordId')
			}
		};
		console.log('>>>>>>> seteo los parámetros : ' + JSON.stringify(params));
		loadcmpevt.setParams(params);
		loadcmpevt.fire();
		console.log('lanzo el evento');
	},
	onsubmitsuccess: function (component, event, helper) {
		let success = event.getParam('success');
		console.log('success? ' + success);
		if (success) {
			var msgToastText;
			switch (component.get('v.msgToast')) {
				case 'save':
					msgToastText = 'Pricing data saved';
					break;
				case 'calculate':
					helper.calculateflow(component, event, helper);
					msgToastText = 'Pricing data saved. \nConnecting to Price Calculation service...';
					break;
				//default:
			}
			helper.showToast(component, event, helper, 'success', msgToastText);
		} else {
			console.log('>>>>>>> onsubmitsuccess error');
		}
	},
	refreshamortization: function () {
		console.log('lanzo');
		var appEvent = $A.get("e.c:PRC_AmortizationCSVInterface_Refresh");
		appEvent.fire();
	}
})