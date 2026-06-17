({

	createChart : function (component) {
		var ready = component.get('v.ready');
		if (ready === false) {
			return;
		}
		var chartCanvas = component.find('chart').getElement();
		var action = component.get('c.revenueCountry');
        action.setParams({
			'recordId': component.get('v.recordId')
        });
        action.setCallback(this, function(response) {
			var state = response.getState();

			if (state === 'SUCCESS') {
			       var resultData = JSON.parse(response.getReturnValue());
                   var data = {
						 labels: resultData.lstCountry,
						 datasets: [
							 {
								 label: "Sum of Current Years Revenues",
								 backgroundColor: "rgba(0, 112, 210, 1)",
								 data: resultData.lstcurrent
							 },
							 {
								 label: "Sum of Current Years Expected Revenues",
								 backgroundColor: "rgba(0, 68, 135, 1)",
								 data: resultData.lstrevenue
							 }
						 ]
					};
                    var chart = new Chart(chartCanvas, {
						type: 'bar',
						data: data,
						options: {
							barValueSpacing: 1,
                            responsive: false,
                            maintainAspectRatio: false,
							scales: {
								yAxes: [{
									ticks: {
										min: 0,
                                        beginAtZero: true,
									},
                                    categoryPercentage: 0,
			                        barPercentage: 0,
                                    scaleLabel: {
                                        display    : true,
                                        labelString: 'Sum of CUrrent Years Revenues'
                                    }
								}],
								xAxes: [{
                                          id: "barline",
                                          categoryPercentage: 0.1,
                                          gridLines: {
                                            display: false
                                          },
                                          stacked: false,
                                          scaleLabel: {
                                            display    : true,
                                            labelString: 'Country'
                                          }
                                        }]
							}
						}
					});
					component.set("v.chartobj",chart);
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
	}
})