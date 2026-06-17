({
  onInit: function (component, event, helper) {
    var action = component.get("c.getScenariotData");
    action.setParams({
      oppId: component.get("v.recordId")
    });

    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        component.set("v.noData", false);
        var scenariosList = response.getReturnValue();
        if (scenariosList && scenariosList.length > 0) {
          helper.createChart(component, scenariosList);
        }
      } else if (state === "ERROR") {
        component.set("v.noData", true);

        // generic error handler
        var errors = response.getError();
        if (errors) {
          console.log("Errors", errors);
          if (errors[0] && errors[0].message) {
            //helper.showToast(component, event, helper, 'error', 'Error: ' + errors[0].message);
            throw new Error("Error: " + errors[0].message);
          }
        } else {
          //helper.showToast(component, event, helper, 'error', 'Unknown Error');
          throw new Error("Unknown Error");
        }
      }
    });

    $A.enqueueAction(action);
  },

  createChart: function (component, scenariosList) {
    var chartCanvas = component.find("chartPRC_2").getElement();
    var barLabelList = [];
    var barDataList = [];
    var line1DataList = [];
    var line2DataList = [];
    var currencyEAD = scenariosList[0].currencyIsoCode;
    scenariosList.forEach(function (element, index, array) {
      barLabelList.push(element.year_id__c);
      barDataList.push(element.ead_amount__c);
      line1DataList.push(element.gf_trans_rar_amount__c);
      line2DataList.push(element.gf_rorc_amount__c);
    });

    var barChart = new Chart(chartCanvas, {
      type: 'bar',
      data: {
        labels: barLabelList,
        datasets: [
          {
            label: 'RAROEC',
            data: line1DataList,
            yAxisID: 'axis-line',
            borderColor: ['rgba(24, 146, 217, 1)'],
            type: 'line',
            //order: 1,
            backgroundColor: 'rgba(24, 146, 217, 1)',
            fill: false
          },

          {
            label: 'RORC',
            data: line2DataList,
            yAxisID: 'axis-line',
            borderColor: ['rgba(217, 137, 24, 1)'],
            type: 'line',
            //order: 2,
            backgroundColor: 'rgba(217, 137, 24, 1)',
            fill: false
          },

          {
            label: 'EAD amount',
            data: barDataList,
            borderColor: ['rgba(0, 68, 129, 1)'],
            backgroundColor: [
              'rgba(0, 68, 129, 1)', 'rgba(0, 68, 129, 1)', 'rgba(0, 68, 129, 1)', 'rgba(0, 68, 129, 1)', 'rgba(0, 68, 129, 1)',
              'rgba(0, 68, 129, 1)', 'rgba(0, 68, 129, 1)', 'rgba(0, 68, 129, 1)', 'rgba(0, 68, 129, 1)', 'rgba(0, 68, 129, 1)',
              'rgba(0, 68, 129, 1)', 'rgba(0, 68, 129, 1)', 'rgba(0, 68, 129, 1)', 'rgba(0, 68, 129, 1)', 'rgba(0, 68, 129, 1)',
              'rgba(0, 68, 129, 1)', 'rgba(0, 68, 129, 1)', 'rgba(0, 68, 129, 1)', 'rgba(0, 68, 129, 1)', 'rgba(0, 68, 129, 1)',
            ],
            //order: 3
          }

        ]
      },

      options: {
        legend: {
          display: true,
          position: 'bottom',
          labels: {
            boxWidth: 15,
            backgroundColor: ['rgba(0, 68, 129, 1)', 'rgba(24, 146, 217, 1)', 'rgba(217, 137, 24, 1)']
          }
        },
        scales: {
          /*xAxes: [{
            display: true,
            stacked: true,
            scaleLabel: {
              display: true,
              labelString: 'Days'
            },
          }, {
            id: 'XX',
            type: 'linear',
            display: false,
            stacked: false,
            scaleLabel: {
              display: false,
              labelString: 'Days'
            },
            ticks: {
              beginAtZero: true,
              stepSize: 1,
              suggestedMax: 125
            }
          }],*/
          yAxes: [{
            display: true,
            stacked: false,
            scaleLabel: {
              display: true,
              labelString: 'EAD amount (' + currencyEAD + ')',
            },
            ticks: {
              beginAtZero: true,
            }
          }, {
            id: 'axis-line',
            display: true,
            stacked: false,
            position: 'right',
            scaleLabel: {
              display: true,
              labelString: 'Percent (%) RAROEC & RORC'
            },
            ticks: {
              beginAtZero: true,
            }
          }]
        }
      }

    });
  }
})