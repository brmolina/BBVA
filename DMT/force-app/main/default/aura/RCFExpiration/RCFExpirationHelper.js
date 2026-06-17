({
    createChart: function (component, helper) {
        let ready = component.get('v.ready');
        if (ready === false) {
            return;
        }
        let actionApex = component.get('c.getData');
        actionApex.setParams({
            'clientId': component.get('v.recordId')
        });
        actionApex.setCallback(this, function (response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                helper.handleSuccess(component,helper, response);
            } else if (state === 'ERROR') {
                helper.handleError(response);
            }
        });
        $A.enqueueAction(actionApex);
    },
    handleError: function(response) {
        let errorApex = response.getError();
        if (errorApex) {
            if (errorApex[0] && errorApex[0].message) {
                console.log('Error message on createReport: ' +
                errorApex[0].message);
            }
        } else {
            console.log('Unknown error');
        }
    },
    handleSuccess: function(component, helper, response) {
        let result = JSON.parse(response.getReturnValue());
        if(result != null) {
            if (Object.values(result).length <= 0 || result.dateCLIP == 'no data') {
                component.set('v.noData', true);
            } else {
                component.set('v.noData', false);
                baseFichaGrupo.setTimeRefresh(component);
    
                let chartLabelDataSet = Object.keys(result.mapData);
                let chartLabelColumns = Object.keys(Object.values(result.mapData)[0]);
                let chartDataColumns1 = Object.values(Object.values(result.mapData)[0]);
                let chartDataColumns2 = Object.values(Object.values(result.mapData)[1]);
    
                let valuesColors = Object.values(result.mapColors);
                const SUMDATASETS = 2;
    
                component.set('v.dateMonth', result.dateCLIP);
    
                let chartLabelColumns2Lines = [];
    
                for (let x = 0; x < chartLabelColumns.length; x++) {
                    chartLabelColumns2Lines.push(chartLabelColumns[x].split("<br>"));
                }
    
                let data = {
                    labels: chartLabelColumns2Lines,
                    datasets: [{
                        label: chartLabelDataSet[1],
                        backgroundColor: valuesColors[1],
                        data: chartDataColumns2
                    },
                    {
                        label: chartLabelDataSet[0],
                        backgroundColor: valuesColors[0],
                        data: chartDataColumns1
                    }]
                };
                helper.drawChart(component, data, SUMDATASETS);
            }
        }
    },
    drawChart: function(component, data, SUMDATASETS) {
        let chartCanvas = component.find('chart').getElement();
        let userCurrencyCode = $A.get("$Locale.currencyCode");
        let cnTooltip = 0;
        let chart = new Chart(chartCanvas, { //NOSONAR esperando callback
            type: 'bar',
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
                    onClick: (evt) => evt.stopPropagation()
                },
                tooltips: {
                    mode: "index",
                    intersect: true,
                    position: 'nearest',
                    bodySpacing: 4,
                    callbacks: {
                        label: function (tooltipItems, data) {
                            let currencyCode = userCurrencyCode;
                            let tooltipText = [];
                            let labels = [];
                            let values = [];

                            labels[0] = data.datasets[0].label || '';
                            values[0] = data.datasets[0].data[tooltipItems.index] || 0;
                            labels[1] = data.datasets[1].label || '';
                            values[1] = data.datasets[1].data[tooltipItems.index] + data.datasets[0].data[tooltipItems.index] || 0;

                            for (let cn = 0; cn < SUMDATASETS; cn++) {

                                values[cn] = parseFloat(values[cn]).toFixed(2);
                                values[cn] += '';
                                let x = values[cn].split('.');
                                let x1 = x[0];
                                let x2 = x.length > 1 ? ',' + x[1] : '';
                                let rgx = /(\d+)(\d{3})/;
                                while (rgx.test(x1)) {
                                    x1 = x1.replace(rgx, '$1' + '.' + '$2');
                                }
                                values[cn] = x1 + x2;

                            }
                            tooltipText.push(' ' + labels[cnTooltip] + ': ' + values[cnTooltip] + ' ' + currencyCode);
                            if (cnTooltip === SUMDATASETS - 1)
                                cnTooltip = 0;
                            else
                                cnTooltip++;

                            return tooltipText;
                        }
                    }
                },
                scales: {
                    xAxes: [{
                        stacked: true,
                        ticks: {
                            autoSkip: false,
                            fontSize: 8
                          }
                    }],
                    yAxes: [{
                        stacked: true
                    }]
                }
            }
        });
    }
})