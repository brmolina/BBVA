({
	displaymodal: function (component, event, helper, displayvalue) {
		console.log('Class: PRC_PricingFlowHandlerHelper.js > Method: displaymodal > component v.recordId : ' + component.get('v.recordId'));
		component.set('v.displaymodal', displayvalue);
	},
	getstate: function (component, event, helper) {
		return new Promise(function (resolve, reject) {
			var action = component.get('c.getstate');
			var params = {
				'opportunityid': component.get('v.recordId')
			};
			var callback = function (response) {
				var value = response.getReturnValue();
				component.set('v.currentstep', value)
				resolve();
			};
			action.setParams(params);
			action.setCallback(this, callback);
			$A.enqueueAction(action);
		});
	},
	selectcomponent: function (recordId, state) {
		var resultado = new Map();
		switch (state) {
			case "Product Selector":
				resultado.set('cmpname', 'c:PRC_ProductSelector');
				resultado.set('params', {
					'recordId': recordId,
					'aura:id': state
				});
				break;
			case "Price Form":
				resultado.set('cmpname', 'c:PRC_PriceForm');
				resultado.set('params', {
					'recordId': recordId,
					'aura:id': state
				});
				break;
			default:
				resultado.set('cmpname', 'c:PRC_PriceBrowserMatrix');
				resultado.set('params', {
					'aura:id': state
				});
				break;
		}
		return resultado;
	},
	loadcomponent: function (component, event, helper, newcomponentname, params) {
		return new Promise(function (resolve, reject) {
			console.log('loadcomponent');
			let pcopy = params;
			console.log('params : ' + JSON.stringify(pcopy));
			console.log('params : ' + params);
			var componentcontainer = component.find('modalbody');
			console.log('load component > component container : ' + componentcontainer);
			$A.createComponent(
				newcomponentname,
				params,
				function (result) {
					if (component.isValid()) {
						console.log('component is valid!');
						componentcontainer.set('v.body', []);
						var containerbody = componentcontainer.get('v.body');
						containerbody.push(result);
						componentcontainer.set('v.body', containerbody);
						resolve();
					} else {
						console.log('component not valid ! ');
						reject();
					}
				}
			);
		});
	},
	loadprogressindicator: function (component) {
		return new Promise(function (resolve, reject) {
			var currentstep = component.get('v.currentstep');
			console.log(currentstep);
			$A.createComponents(
				[
					['lightning:progressStep', { label: 'Product Selector', value: 'Product Selector' }],
					['lightning:progressStep', { label: 'Price Form', value: 'Price Form' }],
					['lightning:progressStep', { label: 'Sensibility Matrix', value: 'Sensibility Matrix' }]
				],
				function (steps) {
					$A.createComponent(
						'lightning:progressIndicator',
						{ currentStep: currentstep },
						function (indicator) {
							indicator.set('v.body', []);
							var indicatorbody = [];
							for (var step of steps) {
								indicatorbody.push(step);
							}
							indicator.set('v.body', indicatorbody);
							var pi = component.find('progressindicator');
							var pibody = [];
							pibody.push(indicator);
							pi.set('v.body', pibody);
							resolve();
						}
					);
				}
			);
		});
	},
	loadbuttons: function (component, event, helper, state) {
		var buttoncontainer = component.find('buttoncontainer');
		switch (state) {
			case 'Product Selector':
				console.log('PS state');
				var params = { 'label': 'Continue', 'aura:id': 'continuebtn', 'onclick': component.getReference('c.continue') };
				helper.createbutton(buttoncontainer, params, true);
				break;
			case 'Price Form':
				console.log('PF state');
				var params_save = { 'label': 'Save', 'aura:id': 'savebtn', 'onclick': component.getReference('c.save') };
				helper.createbutton(buttoncontainer, params_save, true);
				var params_calculate = { 'label': 'Calculate', 'aura:id': 'calculatebtn', 'onclick': component.getReference('c.calculate') };
				helper.createbutton(buttoncontainer, params_calculate, false);
				break;
			default:
				var cprice = { 'label': 'Choose Price', 'aura:id': 'choosebtn', 'onclick': component.getReference('c.chooseprice') };
				helper.createbutton(buttoncontainer, cprice, true);
				console.log('NONE state');
				break;
		}
	},
	createbutton: function (container, params, cleancontainer) {
		$A.createComponent(
			'lightning:button',
			params,
			function (newbutton) {
				let containerbody = container.get('v.body');
				if (cleancontainer) { containerbody = []; }
				containerbody.push(newbutton);
				container.set('v.body', containerbody);
			}
		);
	},
	calculate: function (component) {
		return new Promise(function (resolve, reject) {
			console.log('>>>>>> calculate called !');
			let action = component.get('c.callWS');
			let params = { 'opportunityid': component.get('v.recordId') };
			var callback = function (response) {
				let state = response.getState();
				let value = response.getReturnValue();
				if (state === 'SUCCESS') {
					if (value.wsErrorMsg) {
						reject(value.wsErrorMsg);
					} else {
						component.set('v.response', value);
						resolve();
					}
				} else {
					reject();
				}
			};
			action.setParams(params);
			action.setCallback(this, callback);
			$A.enqueueAction(action);
		});
	},
	chooseprice: function (component) {
		return new Promise(function (resolve, reject) {
			component.savePrice();
			resolve();
		});
	},
	showToast: function (component, event, helper, msgType, msg) {
		var toastEvent = $A.get("e.force:showToast");
		toastEvent.setParams({
			// "title": "Success!",
			"type": msgType,
			"message": msg
		});
		toastEvent.fire();
	},
	deleteAmortizationData: function (component, event, helper) {
		let opportunityId = component.get('v.recordId');
		var action = component.get('c.deleteAmortizationData');
		var params = { 'opportunityId': opportunityId };
		var callback = function (response) {
			let state = response.getState();
			if (state === 'SUCCESS') {
				console.log('>>>>> Amortization Data deleted successfully');
			} else if (state === "ERROR") {
				// generic error handler
				var errors = response.getError();
				if (errors) {
					console.log('>>>>> Error trying to delete Amortization Data: ', errors);
					if (errors[0] && errors[0].message) {
						console.log('>>>>> Error: ' + errors[0].message);
					}
				} else {
					console.log('>>>>>  Error: Unknown Error');
				}
			}
		};
		action.setParams(params);
		action.setCallback(this, callback);
		$A.enqueueAction(action);
	},
	calculateflow: function (component, event, helper) {
		component.set('v.showspinner', true);
		console.log('>>>>>>> (PRC_PricingFlowHandlerController.calculate) SPINNERRRR');
		var wscalled = helper.calculate(component);
		wscalled.then($A.getCallback(function (resolve) {
			var response = component.get('v.response');
			var oppid = component.get('v.recordId');
			let params = {
				'aura:id': 'pricematrix',
				'responseData': response,
				'opportunityId': oppid
			};
			component.set('v.showspinner', false);
			return helper.loadcomponent(component, event, helper, 'c:PRC_PriceBrowserMatrix', params);
		})).then($A.getCallback(function (resolve) {
			component.set('v.currentstep', 'Sensibility Matrix');
			console.log('>>>>> before load btn');
			return helper.loadbuttons(component, event, helper, 'state');
		})).then($A.getCallback(function (resolve) {
			console.log('>>>>> pi cargado');
			return helper.loadprogressindicator(component);
		})).catch(function (reject) {
			console.log('>>>>> Se fue por el catch(function(reject): ' + reject);
			var msgError = 'Error: An internal error occurred while connecting to Amiweb Service. If the problem persists, contact your administrator';
			if (reject) {
				msgError = reject;
			}
			helper.showToast(component, event, helper, 'error', msgError)
		});
	},
	/*
	Funcion que valida los datos insertados en el formulario antes de enviarlos.
	Se controla:
	- La obligatoriedad de rellenar (distinto de “None”) los siguientes campos: type, financing type,
	average life funding, funding curve, amortization type, payment rate, operational currency
	- La obligatoriedad de rellenar en Operational Currency el valor de Proposal Currency
	Devuelve true o false en funcion de su validez
	En el caso de false, ademas deja un mensaje de error
	*/
	validForm: function (body) {
		//Por defecto es valido
		let valid = true;
		//variable que se utilizara para mostrar en el mensaje los campos obligatorios sin rellenar
		let requiredFields = '';
		//let clientTypeIdValue = body.find('clientTypeId').get('v.value');
		//Comprobamos campo Type

		requiredFields = this.checkfield(body, requiredFields, 'ratingGroupId', 'Rating Group');
        requiredFields = this.checkfield(body, requiredFields, 'clientRatingId', 'Client Rating');
        requiredFields = this.checkfield(body, requiredFields, 'clientTypeId', 'Type');
        requiredFields = this.checkfield(body, requiredFields, 'clientIndustryId', 'Client Industry');
        requiredFields = this.checkfield(body, requiredFields, 'officeId', 'Office');
        requiredFields = this.checkfield(body, requiredFields, 'BssA', 'Business Area');
        requiredFields = this.checkfield(body, requiredFields, 'externalRatingId', 'External Rating');
        requiredFields = this.checkfield(body, requiredFields, 'riskProductId', 'Risk Product');
        requiredFields = this.checkfield(body, requiredFields, 'operationalRatingId', 'Operational Rating');
		requiredFields = this.checkfield(body, requiredFields, 'bookingId', 'Booking');
		requiredFields = this.checkfield(body, requiredFields, 'startDateId', 'Start Date');
		requiredFields = this.checkfield(body, requiredFields, 'maturityDateId', 'Maturity Date');
		requiredFields = this.checkfield(body, requiredFields, 'averageLifeFundingid', 'Average life funding');
		requiredFields = this.checkfield(body, requiredFields, 'amortizationTypeId', 'Amortization Type');
		requiredFields = this.checkfield(body, requiredFields, 'paymentRateId', 'Payment rate');
		if(body.find('amortizationTypeId').get('v.value') !== 'USER_DEFINED') {
		  requiredFields = this.checkfield(body, requiredFields, 'paymentFrequencyId', 'Payment Frequency');
		}
		if (requiredFields.length>2) {
			//Si ha habido algun campo vacio, formateamos el mensaje y lo establecemos
			valid = false;
			body.find('validationMessages').setError('Required fields: ' + requiredFields.substring(0, requiredFields.length-2));
		}
		return valid;
	},
	checkfield: function(body,requiredFields,fieldToCheck, errorField) {
		let fields = requiredFields;
		let valueToCheck = body.find(fieldToCheck).get('v.value');
		if (valueToCheck == null || valueToCheck === '') {
			fields = fields + errorField + ' , ';
		}
		return fields;
	},
	validFormSelector: function (body) {
		//Por defecto es valido
		let valid = true;
		//variable que se utilizara para mostrar en el mensaje los campos obligatorios sin rellenar
		let requiredFields = '';
		//let clientTypeIdValue = body.find('clientTypeId').get('v.value');
		//Comprobamos campo Type
		requiredFields = this.checkfield(body, requiredFields, 'riskProductId', 'Product');

		if (requiredFields.length>2) {
			//Si ha habido algun campo vacio, formateamos el mensaje y lo establecemos
			valid = false;
			body.find('validationMessages1').setError('Required fields: ' + requiredFields.substring(0, requiredFields.length-2));
		}
		return valid;
	}
})