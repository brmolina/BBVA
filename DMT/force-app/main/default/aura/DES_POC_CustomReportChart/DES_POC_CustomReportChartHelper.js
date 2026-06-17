({
							
	createChart : function (component) {
		var ready = component.get("v.ready");
		if (ready === false) {
			return;
		}
		var chartCanvas = component.find("chart").getElement();
		console.log('>>>>> ID: ' + component.get("v.recordId"));
		var action = component.get("c.getData");
		action.setParams({
			"clientId": component.get("v.recordId")
		});        
		action.setCallback(this, function(response) {
			var state = response.getState();
			console.log('>>>>> state: ' + state);
			if (state === "SUCCESS") {
				
				var userCurrencyCode = $A.get("$Locale.currencyCode");
				var resultData = JSON.parse(response.getReturnValue());
				var chartData = [];
				var chartLabels = [];
				console.log('>>>>> OBJECT.VALUES: ');
				console.log(Object.values(resultData));
				if (Object.values(resultData).length <= 0){
                    console.log('>>>>> NO SE HAN ENCONTRADO RESULTADOS.');
                    component.set('v.noData', true);
                }else{
                	component.set('v.noData', false);
					chartData = Object.values(resultData);
					chartLabels = Object.keys(resultData);
					console.log(resultData);
					console.log('chartData : ' + chartData);
					console.log('chartLabels : ' + chartLabels);
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
                    //Construct chart
					var chart = new Chart(chartCanvas,{                       
						type: 'doughnut',
						data: {
							labels: chartLabels,						
							datasets: [
								{
									data: chartData,
									backgroundColor: ["#2462B1", "#093977", "#FFC922", "#6996D0"]
								}
							]
						},
						options: {
							title: {
								display: true,
								text: ''
							},
							tooltips: {

								callbacks: {
									label: function(tooltipItem, data) {
										//Saco la label
										var label = data.labels[tooltipItem.index] || '';
										//Saco el valor
										var value = data.datasets[0].data[tooltipItem.index] || 0;
										var currencyCode = userCurrencyCode;
										var tooltipText = '';

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
						   }
						}
					});
				} // fin del ELSE reportResultData.groupingsDown.groupings != null
				
			} else if (state === "ERROR") {
				var errors = response.getError();
				console.log();
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