({
	createChart: function (component, helper) {
        let ready = component.get('v.ready');
        if (ready === false) {
            return;
        }
        let action = component.get('c.getData');
        action.setParams({
            'offerId': component.get('v.recordId'),
            'fieldSum': component.get('v.revenues')
        });
        action.setCallback(this, function (response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                helper.handleSuccessCommOffer(component, response, helper);
            } else if (state === 'ERROR') {
                console.log('Error CommOfferRevenuesHelper method createChart');
            }
        });
        $A.enqueueAction(action);
    },
    handleSuccessCommOffer: function(component, response, helper) {
        if(component.find("chart")) {
            var chartCanvas = component.find("chart").getElement();
        }
        let resultData = JSON.parse(response.getReturnValue());
        let respColors = resultData.mapRowColors;
        let resDatos = resultData.mapSimpleData;
        var chartLabels = [];

        if (Object.values(resDatos).length <= 0) { //NOSONAR
            component.set('v.noData', true);
        } else {
            component.set('v.noData', false);
            baseFichaGrupo.setTimeRefresh(component);

            chartLabels = Object.keys(resultData.mapSimpleData);
            var chartValues = Object.values(resultData.mapSimpleData);

            let dataset = function (vLabel, vBackgrCol, vData, vBorderColor) {
                return {
                    label: vLabel,
                    backgroundColor: vBackgrCol,
                    data: vData,
                    borderColor: vBorderColor,
                    borderWidth: 1
                }
            }

            var vDatasets = helper.fillDataSet(respColors, chartValues, resultData, dataset);
            let data = {
                labels: chartLabels,
                datasets: vDatasets
            };

            let options =  {
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

                tooltips: {
                    mode: 'index',
                    displayColors: false,

                    callbacks: {
                        footer:function (tooltipItems, data) {
                            return helper.footerFunction(data);
                        },
                        label: function (tooltipItem, data) {
                            return helper.labelFunction(chartLabels, chartValues);
                        },
                    }//FIN callbacks
                },

                legend: {
                    display: true,
                    position: "bottom",
                    labels: {
                        fontSize: 12
                    }
                },
            };

            if (chartCanvas) {
                let chart = new Chart(chartCanvas, { //NOSONAR esperando callback...
                    type: 'doughnut',
                    data: data,
                    options: options
                });
            }
        }
    },

    fillDataSet: function(respColors, chartValues, resultData, dataset) {
        let vDatasets = [];
        if (Object.keys(respColors).length > 0) {
            let labels = [];
            var background = [];
            var borderColor = [];
            let data = [];
            for (let indColor = 0; indColor < Object.keys(respColors).length; indColor++) {
                this['listData' + Object.keys(respColors)[indColor]] = [];
                for (let indValue = 0; indValue < chartValues.length; indValue++) {
                    if (Object.keys(respColors)[indColor] === Object.keys(resultData.mapSimpleData)[indValue] ) {
                        this['listData' + Object.keys(respColors)[indColor]].push((chartValues[indValue]));
                    }
                }

                labels.push(Object.keys(respColors)[indColor]);
                data.push(this['listData' + Object.keys(respColors)[indColor]]);
                background.push(baseFichaGrupo.convertHex(Object.values(respColors)[indColor], 100));
                borderColor.push(baseFichaGrupo.convertHex(Object.values(respColors)[indColor], 100));
            }
            let dataSetRow = dataset(labels, background, data, borderColor);
            vDatasets.push(dataSetRow);
        }
        return vDatasets;
    },

    labelFunction: function(chartLabels, chartValues) {
        let tooltipText = [];
        let labels = [];
        let values = [];
        for (let cn = 0; cn < chartLabels.length; cn++) {
            labels[cn] = chartLabels[cn] || '';
            values[cn] = chartValues[cn] || 0;
        }

        for (let cn = 0; cn < values.length; cn++) {
            //COLOCO LOS VALUES CON PUNTOS
            values[cn] = parseFloat(values[cn]);//.toFixed(2);
            values[cn] += '';
            let x = values[cn].split('.');
            let x1 = x[0];
            let x2 = x.length > 1 ? ',' + x[1] : '';
            let rgx = /(\d+)(\d{3})/;
            while (rgx.test(x1)) {
                x1 = x1.replace(rgx, '$1' + '.' + '$2');
            }
            values[cn] = x1 + x2;
            //AHORA GENERO EL TEXTO DEL TOOLTIP
            tooltipText.push(' ' + labels[cn] + ': ' + values[cn]);
        }//FIN
        return tooltipText.sort();
    },

    footerFunction: function(data) {
        let sum = 0;
        let datos = data.datasets[0].data;

        for (let ind = 0; ind < datos.length; ind++) {
            sum += datos[ind][0];
        }
        sum = parseFloat(sum);
        sum += '';
        let x = sum.split('.');
        let x1 = x[0];
        let x2 = x.length > 1 ? ',' + x[1] : '';
        let rgx = /(\d+)(\d{3})/;
        while (rgx.test(x1)) {
            x1 = x1.replace(rgx, '$1' + '.' + '$2');
        }
        sum = x1 + x2;
        return 'Total Amount: ' + sum;
    },

    getDataTable: function (component, helper) {
    	var action = component.get( "c.getDataTable" );
        action.setParams({
      		'offerId': component.get('v.recordId')
    	});

    	action.setCallback(this, function (response) {
            if (response.getState() === 'SUCCESS') {
            	var elements = JSON.parse(response.getReturnValue());
            	component.set('v.members', elements);
            	component.set('v.columns', [
                            {label: 'Opportunity Name', fieldName: 'oppUrl', type: 'url', typeAttributes: { label: { fieldName: 'oppName' }} },
                            {label: 'Booking Country', fieldName: 'oppCountry', type: 'String'},
                            {label: 'Potential Revenues', fieldName: 'oppPotential', type: 'String'},
                    		{label: 'Expected Revenues', fieldName: 'oppExpected', type: 'String'},
                            {label: 'Probability', fieldName: 'oppProb', type: 'String'}
                        ]);
            } else if (state === "ERROR") {
                var errors = response.getError();
                console.error(errors);
            }
        });

        $A.enqueueAction(action);
    }

})