({
	createChart : function(component) {
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
                var resFams = resultData.mapFamCol;
                var resDatos = resultData.mapData;
                console.log('Valor de resFams: ' +resFams);
                console.log('Valor de resDatos: ' +resDatos);
				var chartPrimaryLabels = [];
				var chartSecondLabels = [];
				console.log('Valor de chartSecondLabels: ' +chartSecondLabels);
				if (Object.values(resDatos).length <= 0){
					component.set('v.noData', true);
				}else{
					component.set('v.noData', false);
					chartPrimaryLabels = Object.keys(resDatos);
					var chartSecondGroup = Object.values(Object.values(Object.values(resDatos)));
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

                    var vDatasets = [];
                    var dataset = function (vLabel, vBackgrCol, vData){
                        return {
                            label: vLabel,
                            backgroundColor: vBackgrCol,
                            data: vData
                        }
                    }

                    if (Object.keys(resFams).length > 0){
                       for (var j = 0; j < Object.keys(resFams).length; j++){
                           this['listData' + Object.keys(resFams)[j]] = [];
                           for (var i = 0; i < chartSecondGroup.length; i++){
						       this['listData' + Object.keys(resFams)[j]].push((chartSecondGroup[i][Object.keys(resFams)[j]]));
					        }
                           console.log('listasFams = ' + this['listData' + Object.keys(resFams)[j]]);
                           var datasetFam = dataset (Object.keys(resFams)[j], Object.values(resFams)[j],this['listData' + Object.keys(resFams)[j]]);
                           vDatasets.push(datasetFam);
                       }
                    }

                    var data = {
					  labels: chartPrimaryLabels,
					  datasets: vDatasets
					};

					var chart = new Chart(chartCanvas,{ //NOSONAR esperando callback
						type: 'horizontalBar',
						data: data,
						options: {
							title: {
								display: true,
								text: ''
							},
							tooltips: {
								callbacks: {
									label: function(tooltipItem, data) {
										return baseFichaGrupo.tooltipFunction(tooltipItem, data, true, userCurrencyCode);
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