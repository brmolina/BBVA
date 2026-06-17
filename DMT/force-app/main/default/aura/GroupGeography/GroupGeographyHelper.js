({
		onInit: function (component, event, helper) {
				var action = component.get("c.getAccount");
				action.setParams({
						"clientId": component.get("v.recordId")
				});
				action.setCallback(this, function (response) {
						console.log('::::response - ' + response);
						var state = response.getState();
						console.log(state);
						if (state === "SUCCESS") {
								var obj = response.getReturnValue();
								component.set('v.center', {
										location: {
												City: 'Burkina Faso'
										}
								});
								var str = JSON.stringify(obj);
								console.log(':::valor response json' + str);
								console.log(':::obj.length;:::' + obj.length);
								var lstCountries = [];
								var mapCountriesInfo = {};
								console.log(':::RECORRIENDO response:::');
								for (var i = 0; i < obj.length; i++) {
										lstCountries.push(obj[i].location.Country);
										console.log(':::Country ' + obj[i].location.Country);
										console.log(':::region ' + obj[i].info.region);
										console.log(':::bankerName ' + obj[i].info.bankerName);
										console.log(':::bankerId ' + obj[i].info.bankerId);
										var wrapperData = {};
										wrapperData.region = obj[i].info.region;
										wrapperData.bankerName = obj[i].info.bankerName;
										wrapperData.bankerId = obj[i].info.bankerId;

										obj[i].description = obj[i].description.replace(/null/g, "");

										mapCountriesInfo[obj[i].location.Country] = wrapperData;
								}
								console.log(':::lstCountries - ' + lstCountries);
								var mapaInfoStringified = JSON.stringify(mapCountriesInfo);
								console.log(':::mapaInfoStringified - ' + mapaInfoStringified);
								component.set('v.mapCountriesInfo', mapCountriesInfo);
								component.set('v.lstCountries', lstCountries);
								console.log(':::::::::::::::::: ' + JSON.stringify(obj));
								component.set('v.mapMarkers', obj);

						}

				});
				$A.enqueueAction(action);
		},
		GeographyInfo: function (obj) {
				GeographyInfo.prototype.region = obj[i].info.bankerName;
				GeographyInfo.prototype.bankerId = obj[i].info.bankerId;
				GeographyInfo.prototype.bankerName = obj[i].info.bankerName;
		},
		getCountryPicked: function (cmp, event, helper) {
				console.log("::::::getCountryPicked() hijo helper");
				console.log("::::::event.getSource-------- " + event.getSource().get("v.name"));
				var country = event.getSource().get("v.name");
				if (country === undefined) {
						country = 'clear';
				}
				if (country === 'clear') {
						country = 'Todos';
				}

				cmp.set('v.country', country);

				var evento = cmp.getEvent("countryPickedEvent");

				if (country !== 'Todos') {
						helper.showComponent(cmp, event, helper, "groupGeographyInfo");
						var mapValores = cmp.get("v.mapCountriesInfo");
						var valores = mapValores[country];
						cmp.set('v.region', valores.region);
						cmp.set('v.bankerName', valores.bankerName);
						cmp.set('v.bankerId', valores.bankerId);
				} else {
						helper.hideComponent(cmp, event, helper, "groupGeographyInfo");
				}
				evento.setParams({
						countrySelected: country
				});

				console.log("::::::countrySelected: " + country);
				console.log("::::::event fired" + evento);
				console.log("::::::event fired json " + JSON.stringify(evento));

				evento.fire();
		},
		showComponent: function (cmp, event, helper, nameCmp) {
				$A.util.removeClass(cmp.find(nameCmp), "slds-hide");
		},
		hideComponent: function (cmp, event, helper, nameCmp) {
				$A.util.addClass(cmp.find(nameCmp), "slds-hide");
		}
})