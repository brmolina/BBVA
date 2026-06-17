({
	createChart : function (component) {

        var ready = component.get('v.ready');
		if (ready === false) {
			return;
		}

        var chartCanvas = document.getElementById('chart');
		var action = component.get('c.getData');
		action.setParams({
			'clientId': component.get('v.recordId')
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {

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
					var listIBFData = [];

					for (var i = 0; i < chartSecondGroup.length; i++){
						listGMData.push(chartSecondGroup[i]['GM']);
						listGTBData.push(chartSecondGroup[i]['GTB']);
						listIBFData.push(chartSecondGroup[i]['IBF']);
					}

					var data = {
					  labels: chartPrimaryLabels,
                      pointStyle: 'line',
					  datasets: [{
						  label: 'GM',
						  backgroundColor: '#A4C0FF',
						  borderColor: '#A4C0FF',
                            fill: false,
                            pointBorderColor: 'orange',
                            lineTension: 0,
                            pointBackgroundColor: '#A4C0FF',
                            pointRadius: 5,
                            pointHoverRadius: 10,
                            pointHitRadius: 30,
                            pointBorderWidth: 2,
                            pointStyle: 'rectRounded',
						  data: listGMData
						}, {
						  label: 'GTB',
						  backgroundColor: '#00358C',
						  borderColor: '#00358C',
                            fill: false,
                            //borderDash: [5, 5],
                            pointBorderColor: 'orange',
                            lineTension: 0,
                            pointBackgroundColor: '#00358C',
                            pointRadius: 5,
                            pointHoverRadius: 10,
                            pointHitRadius: 30,
                            pointBorderWidth: 2,
                            pointStyle: 'rectRounded',
						  data: listGTBData
						}, {
						  label: 'IBF',
						  backgroundColor: '#8EDEEA',
						  borderColor: '#8EDEEA',
                            fill: false,
                            pointBorderColor: 'orange',
                            lineTension: 0,
                            pointBackgroundColor: '#8EDEEA',
                            pointRadius: 5,
                            pointHoverRadius: 10,
                            pointHitRadius: 30,
                            pointBorderWidth: 2,
                            pointStyle: 'rectRounded',
						  data: listIBFData
						}]
					};

					var chart = new Chart(chartCanvas,{ //NOSONAR esperando callback
						type: 'line',
						data: data,
						options: {
							title: {
								display: true,
								text: ''
							},
							tooltips: {
								mode: 'index',
								callbacks: {
									label: function(tooltipItem, data) {
										return baseFichaGrupo.tooltipFunction(tooltipItem, data, false, ' %');
									}
								}

							},
							scales: {
								xAxes: [{
									stacked: true
								}],
								yAxes: [{
                                    ticks: {
                                        beginAtZero: true,
                                        min: 0,
                                        max: 100
                                    },
                                }]
							},
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