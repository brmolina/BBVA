({

	createChart : function (component) {
		var ready = component.get('v.ready');
		if (ready === false) {
			return;
		}
		var chartCanvas = component.find('chart').getElement();
		var action = component.get('c.getData');
		action.setParams({
			'gaId': component.get('v.recordId'),
            'chartFilter': component.get('v.chartFilter')
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				console.log('SUCCESS en visitas');

				var resultData = JSON.parse(response.getReturnValue());
                console.log(resultData);
                var resFamilies = resultData.familyColorMap;
                var resDatos = resultData.yearMap;
                console.log(resultData);
				console.log(':::::::resultData keys:::::::' + Object.keys(resDatos));
                console.log(':::::::resultData values:::::::' , Object.values(Object.values(resDatos)));
        		var chartPrimaryLabels = [];


                if(Object.values(resDatos).length <= 0){
                  component.set('v.noData', true);
                }else{
                  component.set('v.noData', false);
                  chartPrimaryLabels = Object.keys(resDatos);
                  var chartSecondGroup = Object.values(Object.values(Object.values(resDatos)));
                    console.log(':::::::chartPrimaryLabels:::::::' , chartPrimaryLabels);
                    console.log(':::::::chartSecondGroup:::::::' , chartSecondGroup);
                    chartPrimaryLabels[chartPrimaryLabels.length - 1] = chartPrimaryLabels[chartPrimaryLabels.length - 1];
                    this.getHour(component);

                    var vDatasets = [];
                    var numFamilies = Object.values(resFamilies).length;
                    console.log('numFamilies: ' + numFamilies);
                    var dataset = function (vLabel, vBackgrCol, vData) {
                        return {
                            label: vLabel,
                            backgroundColor: vBackgrCol,
                            data: vData,
                            fill: false,
                            lineTension: 0,
                            borderColor: vBackgrCol,
                            pointBorderColor: vBackgrCol,
                        }
                    }

                    if (numFamilies > 0) {
                        for (var j = 0; j < Object.keys(resFamilies).length; j++){
                            this['listData' + Object.keys(resFamilies)[j]] = [];
                            for (var i = 0; i < chartSecondGroup.length; i++){
                                this['listData' + Object.keys(resFamilies)[j]].push((chartSecondGroup[i][Object.keys(resFamilies)[j]]));
                                console.log('revenues aux: ', chartSecondGroup[i][Object.keys(resFamilies)[j]]);
                            }
                            console.log('listasFams = ' + this['listData' + Object.keys(resFamilies)[j]]);
                            var datasetDep = dataset (Object.keys(resFamilies)[j], Object.values(resFamilies)[j],this['listData' + Object.keys(resFamilies)[j]]);
                            console.log('datasetDep: ' , datasetDep);
                            vDatasets.push(datasetDep);
                            console.log('vDatasets final: ' , vDatasets);
                        }
                    }

                    var data = {
                        labels: chartPrimaryLabels,
                        pointStyle: 'line',
                        datasets: vDatasets
                    };

                    var chart = new Chart(chartCanvas,{ //NOSONAR esperando callback
						type: 'bar',
						data: data,
						options: {
							tooltips: {
								mode: 'index',
								callbacks: {
									label: function (tooltipItem, data) {
										return baseFichaGrupo.tooltipFunction(tooltipItem, data, false, '');
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
                    component.set("v.chartobj",chart);
                }
            } else if (state === 'ERROR') {
				var errors = response.getError();
				if (errors) {
					if (errors[0] && errors[0].message) {
						console.log('Error message on revenues evolution chart: ' +
									errors[0].message);
					}
				} else {
					console.log('Unknown error');
				}
			}
        });
        $A.enqueueAction(action);
	},

    getHour : function(component) {
        var d = new Date();
        if (d.getHours()>=0 && d.getHours()<10) {
            if (d.getMinutes()>=0 && d.getMinutes()<10){
                component.set('v.timeRefresh', '0' + d.getHours() + ':0' +d.getMinutes());
            } else{
                component.set('v.timeRefresh', '0' + d.getHours() + ':' + d.getMinutes());
            }
        } else {
            if (d.getMinutes()>=0 && d.getMinutes()<10){
                component.set('v.timeRefresh', d.getHours() + ':0' +d.getMinutes());
            } else{
                component.set('v.timeRefresh', d.getHours() + ':' + d.getMinutes());
            }
        }
    }
})