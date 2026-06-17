({
	createChart: function (component, helper) {
		let ready = component.get('v.ready');
        if (ready === false) {
            return;
		}
		let action = component.get('c.getData');
        action.setParams({
            'clientId' : component.get('v.recordId')
		});

		action.setCallback(this, function (response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
				let resultData = JSON.parse(response.getReturnValue());
				if (Object.values(resultData.mapData).length <= 0) {
                    component.set('v.noData', true);
                } else {
					component.set('v.noData', false);
					component.set('v.dateMonth', resultData.dateCLIP);
					baseFichaGrupo.setTimeRefresh(component);
					let dataSetNumber = Object.keys(resultData.mapData).length;
					let dataSetLabels = Object.keys(resultData.mapData);
					let valuesColors = Object.values(resultData.mapColors);
					let valoresDataSet = [];
					let chartLabelColumns = Object.keys(Object.values(resultData.mapData)[0]);

					for(let i = 0; i < dataSetNumber; i++) {
						valoresDataSet.push({
							label: dataSetLabels[i],
							backgroundColor: valuesColors[i],
							data: Object.values(Object.values(resultData.mapData)[i]),
							fill: false,
							borderColor: valuesColors[i],
							lineTension: 0,
                            pointRadius: 5,
                            pointHoverRadius: 10,
                            pointHitRadius: 30,
                            pointBorderWidth: 2,
                            pointStyle: 'rectRounded'
						});
					}

					let data = {
						labels: chartLabelColumns,
						pointStyle: 'line',
                        datasets: valoresDataSet
					};

					helper.drawChart(component, data, dataSetNumber, helper);
				}
			}
		});
		$A.enqueueAction(action);
	},
	drawChart: function (component, data, dataSetNumber, helper) {
		let chartCanvas = component.find('chart').getElement();
		let chart = new Chart(chartCanvas, { //NOSONAR esperando callback
			type: 'line',
			data: data,
			options: {
				responsive: true,
				maintainAspectRatio: false,
				title: {
					display: true,
					text: ''
				},
				legend: {
					display: true,
					position: "bottom",
					labels: {
						fontSize: 12
					},
					onClick: (evt) => evt.stopPropagation(),
				},
				tooltips: {
					mode: "index",
					intersect: true,
					position: 'nearest',
					bodySpacing: 4,
					callbacks: {
						title: function (tooltipItems, data) {
							return helper.formatTitle(data.labels[tooltipItems[0].index]);
						},
						label: function (tooltipItems, data) {
							let tooltipText = [];
							let labels = [];
							let values = [];
							for (let cn = 0; cn < dataSetNumber; cn++) {
								labels[cn] = data.datasets[cn].label || '';
								values[cn] = data.datasets[cn].data[tooltipItems.index] || 0;
								tooltipText.push(' ' + labels[cn] + ': ' + values[cn]);
							}

							return tooltipText;
						}
					}
				},
				scales: {
					xAxes: [{
						stacked: true
					}],
					yAxes: [{
						ticks: {
							callback: function(value, index, values) {
								return value + '%';
							},
							beginAtZero: true,
							min: 0,
							max: 100
						},
					}]
				},
			}
		});
	},
	formatTitle: function(dateToFormat) {
		let dateArray = dateToFormat.split('/');
		let valueToReturn;
		switch(dateArray[0]) {
			case '01':
				valueToReturn = 'Jan ' + dateArray[1];
				break;
			case '02':
				valueToReturn = 'Feb ' + dateArray[1];
				break;
			case '03':
				valueToReturn = 'Mar ' + dateArray[1];
				break;
			case '04': //NOSONAR
				valueToReturn = 'Apr ' + dateArray[1];
				break;
			case '05':
				valueToReturn = 'May ' + dateArray[1];
				break;
			case '06':
				valueToReturn = 'Jun ' + dateArray[1];
				break;
			case '07':
				valueToReturn = 'Jul ' + dateArray[1];
				break;
			case '08':
				valueToReturn = 'Aug ' + dateArray[1];
				break;
			case '09':
				valueToReturn = 'Sep ' + dateArray[1];
				break;
			case '10':
				valueToReturn = 'Oct ' + dateArray[1];
				break;
			case '11':
				valueToReturn = 'Nov ' + dateArray[1];
				break;
			case '12':
				valueToReturn = 'Dec ' + dateArray[1];
				break;
			default:
				break;
		}
		return valueToReturn;
	}
})