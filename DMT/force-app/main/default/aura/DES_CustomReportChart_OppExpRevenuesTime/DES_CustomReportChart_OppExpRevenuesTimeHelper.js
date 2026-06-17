({
							
	createChart : function (component) {
		var ready = component.get("v.ready");
		if (ready === false) {
			return;
		}
		var chartCanvas = component.find("chart").getElement();
		//console.log('>>>>> ID: ' + component.get("v.recordId"));
		var action = component.get("c.getData");
		action.setParams({
			"clientId": component.get("v.recordId")
		});        
		action.setCallback(this, function(response) {
			var state = response.getState();
			console.log('>>>>>AA response: ');
			console.log(JSON.parse(response.getReturnValue()));
			if (state === "SUCCESS") {
				
				var userCurrencyCode = $A.get("$Locale.currencyCode");
				var resultData = JSON.parse(response.getReturnValue());
				//var chartBigGroup = [];
				
				console.log('>>>>> resultData.KEYS: ');
				console.log(Object.keys(resultData));
				var chartPrimaryLabels = [];
				var chartSecondLabels = [];
				var chartSecondData = [];

				if (Object.values(resultData).length <= 0){
					//console.log('>>>>> NO SE HAN ENCONTRADO RESULTADOS.');
					component.set('v.noData', true);
				}else{
					component.set('v.noData', false);
					chartPrimaryLabels = Object.keys(resultData);
					var chartSecondGroup = Object.values(Object.values(Object.values(resultData)));
					console.log('>>>>> chartSecondGroup: ');
					console.log(chartSecondGroup);
					console.log('>>>>> chartPrimaryLabels: ');
					console.log(chartPrimaryLabels);
					console.log('>>>>> chartSecondLabels: ');
					console.log(chartSecondLabels);
					console.log('>>>>> chartSecondData: ');
					console.log(chartSecondData);

					
					var d = new Date();
					if (d.getHours()>=0 && d.getHours()<10){
						if (d.getMinutes()>=0 && d.getMinutes()<10){
							component.set("v.timeRefresh", "0" + d.getHours() + ":0" +d.getMinutes());
						} else{
							component.set("v.timeRefresh", "0" + d.getHours() + ":" + d.getMinutes());
						}    
					}else {
						if (d.getMinutes()>=0 && d.getMinutes()<10){
							component.set("v.timeRefresh", d.getHours() + ":0" +d.getMinutes());
						} else{
							component.set("v.timeRefresh", d.getHours() + ":" + d.getMinutes());
						} 
					}
					var listCFData = [];
					var listGMData = [];
					var listGTBData = [];
					var listIBFData = [];
					
					//RECORRER Object.values(Object.values(resultData))
					for (var i = 0; i < chartSecondGroup.length; i++){
						console.log('>>>>> CHARTSECONDGROUP[i]');
						console.log(chartSecondGroup[i]);
						listCFData.push(chartSecondGroup[i]['CF']);
						listGMData.push(chartSecondGroup[i]['GM']);
						listGTBData.push(chartSecondGroup[i]['GTB']);
						listIBFData.push(chartSecondGroup[i]['IBF']);
					}
					console.log('>>>>> listCFData : ');
					console.log(listCFData);
					console.log('>>>>> listGMData : ');
					console.log(listGMData);
					console.log('>>>>> listGTBData : ');
					console.log(listGTBData);
					console.log('>>>>> listIBFData : ');
					console.log(listIBFData);
					
					var data = {
					  labels: chartPrimaryLabels,
					  datasets: [{
						  label: "CF",
						  backgroundColor: "#20A5F2",
						  data: listCFData
						}, {
						  label: "GM",
						  backgroundColor: "#A4C0FF",
						  data: listGMData
						}, {
						  label: "GTB",
						  backgroundColor: "#00358C",
						  data: listGTBData
						}, {
						  label: "IBF",
						  backgroundColor: "#8EDEEA",
						  data: listIBFData
						}]
					};
					var cnTooltip = 0;
					var chart = new Chart(chartCanvas,{                       
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
										//Saco la label

										console.log('>>>>> data.datasets:');
										console.log(data.datasets);
										console.log('>>>>> data.datasets[TOOLTIP]:');
										console.log(data.datasets[tooltipItem.index]);
										console.log('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ');
										console.log('>>>>> value TOOLTIP: ');
										console.log(data.datasets[tooltipItem.index].data[tooltipItem.index]);
										console.log('>>>>> label TOOLTIP: ');
										console.log(data.datasets[tooltipItem.index].label);
										var label = data.datasets[tooltipItem.index].label || '';
										//Saco el valor
										var value = data.datasets[tooltipItem.index].data[tooltipItem.index] || 0;
										var currencyCode = userCurrencyCode;
										var tooltipText = '';
										var labels = [];
										var values = [];
										for(var cn = 0; cn < 4; cn ++){
											labels[cn] = data.datasets[cn].label || '';
											values[cn] = data.datasets[cn].data[tooltipItem.index] || 0;
										}
										console.log('**********************************************');
										console.log('>>>>> labels: ');
										console.log(labels);
										console.log('>>>>> values: ');
										console.log(values);
										value = parseFloat(value).toFixed(2);
										//AHORA VOY A ABREVIAR EL VALUE PARA QUE QUEDE MAS LIMPIO Y MAS RAPIDO DE VER
										/*	var suffixes = ["", "k", "m", "b","t"];
										    var suffixNum = Math.floor((""+value).length/3);
										    var shortValue = parseFloat((suffixNum != 0 ? (value / Math.pow(1000,suffixNum)) : value).toPrecision(2));
										    if (shortValue % 1 != 0) {
										        var shortNum = shortValue.toFixed(1);
										    }
										    value = shortValue+suffixes[suffixNum];
										*/
										
										for(var cn = 0; cn < 4; cn ++){

											//COLOCO LOS VALUES CON PUNTOS
											values[cn] = parseFloat(values[cn]).toFixed(2);
											values[cn] += '';
											var x = values[cn].split('.');
											var x1 = x[0];
											var x2 = x.length > 1 ? ',' + x[1] : '';
											var rgx = /(\d+)(\d{3})/;
											while (rgx.test(x1)) {
												x1 = x1.replace(rgx, '$1' + '.' + '$2');
											}
											values[cn] = x1 + x2;

											//AHORA GENERO EL TEXTO DEL TOOLTIP
											
										}//FIN
										tooltipText += ' ' + labels[cnTooltip] + ': ' + values[cnTooltip] + ' ' + currencyCode;
										if(cnTooltip == 3)
											cnTooltip = 0;
										else
											cnTooltip ++;
										
										return tooltipText;
									}
								}//FIN callbacks
							},
							/*tooltips: {

								callbacks: {
									label: function(tooltipItem, data) {
										//Saco la label
										var label = data.labels[tooltipItem.index] || '';
										//Saco el valor
										var value = data.datasets[0].data[tooltipItem.index] || 0;
										var currencyCode = userCurrencyCode;
										var tooltipText = '';

										value = parseFloat(value).toFixed(2);
										value += '';
										var x = value.split('.');
										var x1 = x[0];
										var x2 = x.length > 1 ? ',' + x[1] : '';
										var rgx = /(\d+)(\d{3})/;
										while (rgx.test(x1)) {
											x1 = x1.replace(rgx, '$1' + '.' + '$2');
										}
										value = x1 + x2;
										//AHORA GENERO EL TEXTO DEL TOOLTIP
										tooltipText = ' ' + label + ': ' + value + ' ' + currencyCode;
										return tooltipText;
									}
								}//FIN callbacks
							},
						   //cutoutPercentage: 55,
							
						   legend:{
								showInLegend: true,
								position: "right",
								display: true, 
								fullWidth:true,
								labels:{
									boxWidth:40, 
									fontSize:10, 
									fontStyle:'normal', 
									fontColor:'#666', 
									usePointStyle:true
								}
						   },*/
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
				} // fin del ELSE reportResultData.groupingsDown.groupings != null
				
			} else if (state === "ERROR") {
				var errors = response.getError();
				//console.log();
				if (errors) {
					if (errors[0] && errors[0].message) {
						console.log("Error message on createReport: " +
									errors[0].message);
					}
				} else {
					console.log("Unknown error");
				}
			}
		});
		$A.enqueueAction(action);
	}
})