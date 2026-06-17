({
    createChart: function (component) {
        let ready = component.get("v.ready");
        if (ready === false) {
            return;
        }
        if(component.find("chart")) {
            var chartCanvas = component.find("chart").getElement();
        }

        let actionCmp = component.get("c.getData");
        let familyCmp = component.get("v.familyParam");
        let stageOption = component.get("v.stageOption");
        actionCmp.setParams({
            "clientId": component.get("v.recordId"),
            "family": familyCmp,
            "stageOption": stageOption,
            "byProduct": component.get("v.byProduct"),
            "byCountryBooking": component.get("v.byCountry"),
            "countryClient": component.get("v.countryParam")
        });


        actionCmp.setCallback(this, function (response) {
            const state = response.getState();
            if (state === "SUCCESS") {
                let userCurrencyCode = $A.get("$Locale.currencyCode");
                let resultData = JSON.parse(response.getReturnValue());
                console.log('::::resultData: ' + JSON.stringify(resultData));
                let respColors = resultData.mapRowColors;
                let resDatos = resultData.mapSimpleData;
                var labelsForChart = [];

                if (resultData == null || resDatos == null || baseFichaGrupo.isEmpty(resDatos) || respColors == null) {
                    component.set('v.noData', true);
                } else {
                    component.set('v.noData', false);
                    baseFichaGrupo.setTimeRefresh(component);

                    labelsForChart = Object.keys(resultData.mapSimpleData);
                    var valuesForChart = Object.values(resultData.mapSimpleData);

                    var valuesDataset = [];
                    let dataset = function (vLabel, vBackgrCol, vData, vBorderColor) {
                        return {
                            label: vLabel,
                            backgroundColor: vBackgrCol,
                            data: vData,
                            borderColor: vBorderColor,
                            borderWidth: 1,
                            // pointColor: vBackgrCol,
                            // strokeColor: vBackgrCol
                        }
                    }


                    if (Object.keys(respColors).length > 0) {
                        let labels = [];
                        var background = [];
                        var borderColor = [];
                        let data = [];
                        for (let indexColor = 0; indexColor < Object.keys(respColors).length; indexColor++) {
                            this['listData' + Object.keys(respColors)[indexColor]] = [];
                            console.log(':::::Object.keys(respColors)[indexColor]]::' + Object.keys(respColors)[indexColor] + ' ::' + Object.values(respColors)[indexColor]);
                            for (let indValue = 0; indValue < valuesForChart.length; indValue++) {
                                console.log([Object.keys(respColors)[indexColor]]);
                                if (Object.keys(respColors)[indexColor] === Object.keys(resultData.mapSimpleData)[indValue] ) {
                                    this['listData' + Object.keys(respColors)[indexColor]].push((valuesForChart[indValue]));
                                }
                            }

                            labels.push(Object.keys(respColors)[indexColor]);
                            data.push(this['listData' + Object.keys(respColors)[indexColor]]);
                            background.push(baseFichaGrupo.convertHex(Object.values(respColors)[indexColor], 100));
                            borderColor.push(baseFichaGrupo.convertHex(Object.values(respColors)[indexColor], 100));
                        }
                        let dataSetRow = dataset(labels, background, data, borderColor);
                        console.log(':::vDatasets global::: ' + JSON.stringify(dataSetRow));
                        valuesDataset.push(dataSetRow);
                    }

                    let data = {
                        labels: labelsForChart,
                        datasets: valuesDataset
                    };

                    let optionsChart =  {
                        segmentShowStroke: true,
                        segmentStrokeColor: "#fff",
                        segmentStrokeWidth: 2,
                        percentageInnerCutout: 50,
                        animationSteps: 100,
                        animationEasing: "easeOutBounce",
                        cutoutPercentage: 40,
                        animateRotate: true,
                        animateScale: false,
                        responsive: true,
                        maintainAspectRatio: false,
                        showScale: true,


                        tooltips: {
                            mode: 'index',
                            displayColors: true,

                            callbacks: {
                                footer:function (tooltipItems, data) {
                                    let sumatorio = 0;
                                    let dataDataset = data.datasets[0].data;

                                    for (let ind = 0; ind < dataDataset.length; ind++) {
                                        sumatorio += dataDataset[ind][0];

                                    }
                                    sumatorio = parseFloat(sumatorio);
                                    sumatorio += '';
                                    let x = sumatorio.split('.');
                                    let x1 = x[0];
                                    let x2 = x.length > 1 ? ',' + x[1] : '';
                                    let regex = /(\d+)(\d{3})/;
                                    while (regex.test(x1)) {
                                        x1 = x1.replace(regex, '$1' + '.' + '$2');
                                    }
                                    sumatorio = x1 + x2;
                                    return 'Total Amount: ' + sumatorio + ' ' + userCurrencyCode;
                                },
                                label: function (tooltipItem, data) {
                                    let textForTooltip = [];
                                    let labelsForTooltip = [];
                                    let valuesForTooltip = [];
                                    for (let counter = 0; counter < labelsForChart.length; counter++) {
                                        labelsForTooltip[counter] = labelsForChart[counter] || '';
                                        valuesForTooltip[counter] = valuesForChart[counter] || 0;
                                    }


                                    for (let counter = 0; counter < valuesForTooltip.length; counter++) {
                                        //COLOCO LOS VALUES CON PUNTOS
                                        valuesForTooltip[counter] = parseFloat(valuesForTooltip[counter]);//.toFixed(2);
                                        valuesForTooltip[counter] += '';
                                        let x = valuesForTooltip[counter].split('.');
                                        let x1 = x[0];
                                        let x2 = x.length > 1 ? ',' + x[1] : '';
                                        let regex = /(\d+)(\d{3})/;
                                        while (regex.test(x1)) {
                                            x1 = x1.replace(regex, '$1' + '.' + '$2');
                                        }
                                        valuesForTooltip[counter] = x1 + x2;

                                        //AHORA GENERO EL TEXTO DEL TOOLTIP
                                        textForTooltip.push(' ' + labelsForTooltip[counter] + ': ' + valuesForTooltip[counter] + ' ' + userCurrencyCode);
                                    }

                                    return textForTooltip.sort();
                                },

                            }//FIN callbacks
                        },

                        legend: {
                            display: true,
                            position: "bottom",
                            labels: {
                                fontSize: 12
                            }
                        }
                    };
                    if (chartCanvas) {
                        let chart = new Chart(chartCanvas, { //NOSONAR esperando callback...
                                            type: 'doughnut',
                                            data: data,
                                            options: optionsChart

                                        });
                    }
                }

            } else if (state === 'ERROR') {
                const errorsCmp = response.getError();
                if (errorsCmp) {
                    if (errorsCmp[0] && errorsCmp[0].message) {
                        console.log('Error message on createReport: ' +
                        errorsCmp[0].message);
                    }
                } else {
                    console.log('Unknown error');
                }
            }
        });
        $A.enqueueAction(actionCmp);
    },

})