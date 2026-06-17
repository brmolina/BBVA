({
    createChart : function (component) {
        var ready = component.get("v.ready");
        if (ready === false) {
            return;
        }
        var chartCanvas = component.find("chart").getElement();
        console.log('>>>>> ID: ' + component.get("v.recordId"));
        var action = component.get("c.getDataChart");
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

                if (Object.values(resultData).length <= 0){
                    console.log('>>>>> NO SE HAN ENCONTRADO RESULTADOS.');
                    component.set('v.noData', true);
                }else{
                	component.set('v.noData', false);
                    chartData = Object.values(resultData);
                    chartLabels = Object.keys(resultData);
                    /*if(chartLabels.length >= 7){//si el tamaño es mas de 7, muestro solo las primeras 7 legends
                        chartLabels.length = 7;
                    }*/
                    
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
                     /*  for(var cn = 0; cn < resultData.length; cn++){
                            console.log('cn: ' + cn);
                            console.log(resultData[cn]);
                            chartData.push(resultData[cn].expr0);
                            chartLabels.push(resultData[cn].DES_Product_Family__c);
                        }            
                        */                    
                    
                    // Definimos los colores del donut
                    var countryColors = [];
                    var options = ["#00A1E0","#16325C","#76DED9","#08A69E","#E2CE7D","#E69F00","#C23934","#FFB75D","#60B17D","#00716B"];
					var cont = 0;
                    for (var i = 0; i < chartData.length; i++){
                        countryColors.push(options[cont]);
                        cont ++;
                        if(cont >= options.length)
                            cont = 0;
                    }
                    console.log('>>>>> options.length.' + options.length);
                    console.log('>>>>> countryColors.' + countryColors);
                    console.log('>>>>> chartData.' + chartData);
                   	
                    // Construimos el grafico 
                    if(chartLabels.length >= 14){
                        var chart = new Chart(chartCanvas,{                       
	                            type: 'doughnut',
	                            data: {
	                                labels: chartLabels,						
	                                datasets: [
	                                    {
	                                        data: chartData,
	                                        backgroundColor: countryColors
	                                    }
	                                ]
	                            },
	                            options: {
	                                'responsive': true,
	                                'maintainAspectRatio': true,
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
	                            
	                            legend:{
	                                showInLegend: true,
	                                position: "right",
	                                display: true, 
	                                fullWidth:false,
	                                labels:{
	                                    boxWidth:0, 
	                                    fontSize:10, 
	                                    fontStyle:'normal', 
	                                    fontColor:'#666', 
	                                    usePointStyle:true
	                                }
	                           }
                            }
                        });
                    }else{
                        var chart = new Chart(chartCanvas,{                       
                            type: 'doughnut',
                            data: {
                                labels: chartLabels,						
                                datasets: [
                                    {
                                        data: chartData,
                                        backgroundColor: countryColors
                                    }
                                ]
                            },
                            options: {
                                'responsive': true,
                                'maintainAspectRatio': true,
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
                    }

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