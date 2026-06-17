({

	createChart : function(component) {
		var ready = component.get('v.ready');
		if (ready === false) {
			return;
		}
		var chartCanvas = component.find('chart').getElement();
		var action = component.get('c.getData');
		action.setParams({
			'clientId': component.get('v.recordId'),
			'family': component.get('v.familyParam'),
			'topN': component.get('v.topN')
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var userCurrencyCode = $A.get("$Locale.currencyCode");
				var resultData = JSON.parse(response.getReturnValue());
                var resFams = resultData.mapFamCol;
				var resDatos = resultData.mapData;
				let dimension = component.get('v.mode')==='four'?8:12;
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
										console.log('vDatasets = ' + JSON.stringify(vDatasets));
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
								text: '',
								maintainAspectRatio: false,
							},
							legend: {
								display: true,
								position: "bottom",
								labels: {
									fontSize: dimension
								}
							},
							// legend: {
							// 	display: false
							// },
							legendCallback: function (chart) {
								alert('legendCallback init: ' );
								let divLegends = component.find("chartjs-legend");
								var text = [];
								text.push('<ul class="' + chart.id + '-legend">');
								for (var i = 0; i < chart.data.datasets.length; i++) {

									text.push('<li><span style="background:' +
									chart.data.datasets[i].borderColor + ';width:1px;height:1px  "></span><span id="legend-' + i +
									'-item" style=""   onclick="updateDataset(event, ' + '\'' + i + '\'' + ')">');

									if (chart.data.datasets[i].label) {
										text.push(chart.data.datasets[i].label);
									}
									text.push('</span></li>');
								}
								text.push('</ul>');
								divLegends.innerHTML = chart.generateLegend();
								alert('divLegends: ' + divLegends);
								return text.join("");
							},
							elements: {
								line: {
									tension: 0,
								}
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
											stacked: true,
											ticks: {
													fontSize: 10
											}
									}],
									yAxes: [{
											stacked: true,
											ticks: {
													fontSize: 8
											}
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
	},

    createEnglobaDate : function (component) {
    var ready = component.get("v.ready");
    if(ready === false) {
      return;
    }
        var actGetEngloba = component.get("c.getEnglobaDate");
        var dateEngloba = component.get ("v.dateEngloba");

        actGetEngloba.setCallback(this, function(response){
            var state = response.getState();
      if(state === "SUCCESS") {
         var resultData = response.getReturnValue();
               console.log("EnglobaDate: " +resultData);
               component.set("v.dateEngloba", resultData);
            }else if(state === "ERROR") {
        var errors = response.getError();
        if(errors){
          if(errors[0] && errors[0].message){
            console.log("Error message on createReport: " +
                  errors[0].message);
          }
        }else{
          console.log("Unknown error");
        }
      }
        });
        $A.enqueueAction(actGetEngloba);
  }

})