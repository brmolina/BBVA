({
    createChart : function (component) {
        var ready = component.get("v.ready");
        if (ready === false) {
            return;
        }
        var chartCanvas = component.find("chart").getElement();
        
        var action = component.get("c.getreport");
        action.setParams({
            "clientId": component.get("v.clientId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var reportResultData = JSON.parse(response.getReturnValue());
                console.log('------------ response.getReturnValue ------------> '+ response.getReturnValue());                

                var chartData = [];
                var chartLabels = [];                                             
                
                if (reportResultData.groupingsDown.groupings == null){
                    console.log('----------- reportResultData.groupingsDown.groupings es nulo: No hay datos en el report.')
                }
                else{
                    for(var i=0; i < (reportResultData.groupingsDown.groupings.length); i++){
                        //Collect all labels for Chart.js data
                        var labelTemp = reportResultData.groupingsDown.groupings[i].label;
                        chartLabels.push(labelTemp);
    
                        var keyTemp = reportResultData.groupingsDown.groupings[i].key;
    
                        //Collect all values for Chart.js data
                        var valueTemp = reportResultData.factMap[keyTemp + '!T'].aggregates[0].value ;
                        chartData.push(valueTemp);
                    }
                    //Construct chart
                    var chart = new Chart(chartCanvas,{
                        type: 'bar',
                        data: {
                            labels: chartLabels,
                            datasets: [
                                {
                                    label: "Sum of Amount",
                                    data: chartData,
                                    backgroundColor: [
                                        "#094fa4","#0065c1", "#009ee5", "#52bcec", "#88d1f2", "#b5e5f9",
                                        "#F8C471",
                                        "#3498DB",
                                        "#00BCD4",
                                        "#D32F2F",
                                        "#82E0AA",
                                        "#AFB42B"
                                    ]
                                }
                            ]
                        },
                        options: {
                            cutoutPercentage: 75,
                            maintainAspectRatio: false,
                            title: {
                                display: true,
                                text: 'RAR de Cliente'
                            },
                            legend: {
                                display: false,
                                position:'right',
                                fullWidth:false,
                                reverse:true,
                                labels: {
                                    fontColor: '#000',
                                    fontSize:10,
                                    fontFamily:"Salesforce Sans, Arial, sans-serif SANS_SERIF"
                                },
                                layout: {
                                    padding: 70,
                                }
                            },
                            scales: {
                                    xAxes: [{
                                      scaleLabel: {
                                        display: true,
                                        labelString: 'Year'
                                      }
                                    }],
                                    yAxes: [{
                                      scaleLabel: {
                                        display: true,
                                        labelString: 'Sum of Amount'
                                      },
                                      ticks: {
                                            beginAtZero: true
                                        }
                                    }]
                                  }  
                        }
                    });
                
            	} // fin del ELSE reportResultData.groupingsDown.groupings != null
                
            } else if (state === "ERROR") {
                var errors = response.getError();
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