({

    createChart: function (component, helper) {
        let ready = component.get('v.ready');
        if (ready === false) {
            return;
        }
        let action = component.get('c.getData');
        action.setParams({
            'clientId': component.get('v.recordId'),
            'family': component.get('v.familyParam'),
            'monthsToDisplay': component.get('v.monthsToDisplay')
        });
        action.setCallback(this, function (response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                helper.successFunction(component, response, helper);
            } else if (state === 'ERROR') {
                helper.errorFunction(response);
            }
        });
        $A.enqueueAction(action);
    },
    successFunction: function(component, response, helper) {
        let chartCanvas = component.find('chart').getElement();
        const userCurrencyCode = $A.get('$Locale.currencyCode');
        let resultData = JSON.parse(response.getReturnValue());
        var resCols = resultData.mapColumns;
        var resDatos = resultData.mapData;

        if (!resDatos || Object.values(resDatos).length <= 0) {
            component.set('v.noData', true);
        } else {
            component.set('v.noData', false);
            baseFichaGrupo.setTimeRefresh(component);

            let chartLabelColumns = Object.keys(resDatos);
            let chartLabelColumns2Lines = [];

            for (let x = 0; x < chartLabelColumns.length; x++) {
                chartLabelColumns2Lines.push(chartLabelColumns[x].split(' '));
            }

            var chartSecondGroup = Object.values(resDatos);

            var vDatasets = [];
            var dataset = function (vLabel, vBackgrCol, vData) {
                return {
                    label: vLabel,
                    backgroundColor: vBackgrCol,
                    data: vData
                }
            }

            vDatasets = helper.fillDataSet(resCols, chartSecondGroup, dataset);

            let total = 0;

            let data = {
                labels: chartLabelColumns2Lines,
                datasets: vDatasets
            };

            let options = {
                segmentShowStroke: true,
                segmentStrokeColor: "#fff",
                segmentStrokeWidth: 2,
                percentageInnerCutout: 50,
                animationSteps: 100,
                animationEasing: "easeOutBounce",
                animateRotate: true,
                animateScale: false,
                responsive: true,
                cutoutPercentage: 40,
                maintainAspectRatio: false,
                showScale: true,

                legend: {
                    display: true,
                    position: "bottom",
                    labels: {
                        fontSize: 12
                    }
                },
                tooltips: {
                    mode: 'index',
                    displayColors: true,

                    callbacks: {
                        afterTitle: function () {
                            total = 0;
                        },
                        footer: function (tooltipItem) {
                            for(let i = 0; i < tooltipItem.length; i++) {
                                total += tooltipItem[i].yLabel;
                            }

                            return "Total: "  + baseFichaGrupo.parseToCurrency(total) + ' ' + userCurrencyCode;
                        },
                        label: function (tooltipItem, data) {
                            return baseFichaGrupo.tooltipFunction(tooltipItem, data, false, userCurrencyCode);
                        },
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
            };
            helper.drawChartAux(chartCanvas, data, options);
        }
    },
    fillDataSet: function(resCols, chartSecondGroup, dataset) {
        var vDatasets = [];
        if (Object.keys(resCols).length > 0) {
            for (var j = 0; j < Object.keys(resCols).length; j++) {
                this['listData' + Object.keys(resCols)[j]] = [];

                for (var i = 0; i < chartSecondGroup.length; i++) {
                    this['listData' + Object.keys(resCols)[j]].push((chartSecondGroup[i][Object.keys(resCols)[j]]));
                }

                var datasetFam = dataset(Object.keys(resCols)[j], Object.values(resCols)[j], this['listData' + Object.keys(resCols)[j]]);
                vDatasets.push(datasetFam);
            }
        }
        return vDatasets;
    },
    errorFunction: function(response) {
        let errors = response.getError();
        if (errors) {
            if (errors[0] && errors[0].message) {
                console.log('Error message on createReport: ' + errors[0].message);
            }
        } else {
            console.log('Unknown error');
        }
    },
    drawChartAux: function(chartCanvas, data, options) {
        if (chartCanvas) {
            let chart = new Chart(chartCanvas, { //NOSONAR esperando callback...
                type: 'bar',
                data: data,
                options: options
            });
        }
    }
})