({

    createChart: function (component) {
        let ready = component.get('v.ready');
        if (ready === false) {
            return;
        }
        let chartCanvas = component.find('chart').getElement();
        let action = component.get('c.getData');
        action.setParams({
            'clientId': component.get('v.recordId'),
            'typeAmount': component.get('v.typeAmount')
        });
        action.setCallback(this, function (response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                let userCurrencyCode = $A.get('$Locale.currencyCode');
                let resultData = JSON.parse(response.getReturnValue());
                let chartPrimaryLabels = [];

                if (Object.values(resultData).length <= 0) {
                    component.set('v.noData', true);
                } else {
                    component.set('v.noData', false);
                    baseFichaGrupo.setTimeRefresh(component);

                    chartPrimaryLabels = Object.keys(resultData);
                    let chartSecondGroup = Object.values(Object.values(Object.values(resultData)));


                    let lstCONSUMEDvalues = [];
                    let lstLIMITvalues = [];
                    const SUMDATASETS = 2;

                    for (let i = 0; i < chartSecondGroup.length; i++) {
                        lstCONSUMEDvalues.push(chartSecondGroup[i]['CONSUMED']);
                        lstLIMITvalues.push(chartSecondGroup[i]['LIMIT']);

                    }

                    let data = {
                        labels: chartPrimaryLabels,
                        datasets: [{
                            label: 'CONSUMPTION',
                            backgroundColor: '#043263',
                            data: lstCONSUMEDvalues
                        },
                        {
                            label: 'LIMIT',
                            backgroundColor: '#1973B8',
                            data: lstLIMITvalues
                        }]
                    };
                    let cnTooltip = 0;
                    let chart = new Chart(chartCanvas, { //NOSONAR esperando callback
                        type: 'bar',
                        data: data,

                        options: {
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
                                mode: 'index',
                                callbacks: {
                                    footer: function (tooltipItems, data) {
                                        let available = tooltipItems[1].yLabel || 0;

                                        available = parseFloat(available);
                                        available += '';
                                        let x = available.split('.');
                                        let x1 = x[0];
                                        let x2 = x.length > 1 ? ',' + x[1] : '';
                                        let rgx = /(\d+)(\d{3})/;
                                        while (rgx.test(x1)) {
                                            x1 = x1.replace(rgx, '$1' + '.' + '$2');
                                        }
                                        available = x1 + x2;
                                        return 'Available: ' + available + ' ' + userCurrencyCode;
                                    },
                                    label: function (tooltipItems, data) {
                                        let currencyCode = userCurrencyCode;
                                        let tooltipText = [];
                                        let labels = [];
                                        let values = [];
                                        // for (let cn = 0; cn < SUMDATASETS; cn++) {
                                        //     labels[cn] = data.datasets[cn].label || '';
                                        //     values[cn] = data.datasets[cn].data[tooltipItems.index] || 0;
                                        // }
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
                let errors = response.getError();
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