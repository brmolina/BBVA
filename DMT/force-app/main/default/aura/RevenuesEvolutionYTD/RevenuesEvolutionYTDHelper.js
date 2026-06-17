({

	createChart : function (component) {
		var ready = component.get('v.ready');
		if (ready === false) {
			return;
		}
		var chartCanvas = component.find('chart').getElement();
		var action = component.get('c.getData');
		action.setParams({
			'clientId': component.get('v.recordId')
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {

				var userCurrencyCode = $A.get("$Locale.currencyCode");
				var resultData = JSON.parse(response.getReturnValue());
				var chartPrimaryLabels = [];

				if (Object.values(resultData).length <= 0){
					component.set('v.noData', true);
				}else{
					component.set('v.noData', false);
					chartPrimaryLabels = Object.keys(resultData);
					var chartSecondGroup = Object.values(Object.values(Object.values(resultData)));

					var d = new Date();
					if (d.getHours()>=0 && d.getHours()<10){
						if (d.getMinutes()>=0 && d.getMinutes()<10){
							component.set('v.timeRefresh', '0' + d.getHours() + ':0' +d.getMinutes());
						} else{
							component.set('v.timeRefresh', '0' + d.getHours() + ':' + d.getMinutes());
						}
					}else {
						if (d.getMinutes()>=0 && d.getMinutes()<10){
							component.set('v.timeRefresh', d.getHours() + ':0' +d.getMinutes());
						} else{
							component.set('v.timeRefresh', d.getHours() + ':' + d.getMinutes());
						}
					}

					var listGMData = [];
					var listGTBData = [];
					var listGFData = [];

					for (var i = 0; i < chartSecondGroup.length; i++){
						listGMData.push(chartSecondGroup[i]['GM']);
						listGTBData.push(chartSecondGroup[i]['GTB']);
						listGFData.push(chartSecondGroup[i]['IBF']);
					}

					var data = {
					  labels: chartPrimaryLabels,
					  datasets: [{
						  label: 'GM',
						  backgroundColor: '#A4C0FF',
						  data: listGMData
						}, {
						  label: 'GTB',
						  backgroundColor: '#00358C',
						  data: listGTBData
						}, {
						  label: 'IBF',
						  backgroundColor: '#8EDEEA',
						  data: listGFData
						}]
					};
					var chart = new Chart(chartCanvas,{ //NOSONAR esperando callback
						type: 'bar',
						data: data,
						options: {
							tooltips: {
								mode: 'index',
								callbacks: {
									label: function (tooltipItem, data) {
										return baseFichaGrupo.tooltipFunction(tooltipItem, data, false, userCurrencyCode);
									}
								}

							},

							scales: {
								xAxes: [{
									stacked: true
								}],
								yAxes: [{
									stacked: true
								}]
							}
						}
					});
				}

			} else if (state === 'ERROR') {
				var errors = response.getError();
				if (errors) {
					if (errors[0] && errors[0].message) {
						console.log('Error message on createReport: ' +
									errors[0].message);
					}
				} else {
					console.log('Unknown error');
				}
			}
		});
		$A.enqueueAction(action);
	}
})