({
  onInit: function (component, event, helper) {
    var action = component.get("c.getOppLineItemData");
    action.setParams({
      oppId: component.get("v.recordId")
    });

    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        component.set("v.noData", false);
        var oli = response.getReturnValue();
        helper.createChart(component, oli);

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

  createChart: function (component, oliData) {
    var chartCanvas = component.find("chartPRC").getElement();
    var barChart = new Chart(chartCanvas, {
      type: 'bar',
      data: {
        labels: ["RAROEC with Funding", "RAROEC without Funding", "RORC with Funding", "RORC without Funding"],
        datasets: [{
          label: 'Percent (%)',
          data: [oliData.gf_fdg_trd_prpsl_rar_tot_per__c, oliData.gf_nfdg_trd_prpsl_rar_tot_per__c,
            oliData.gf_trd_prpsl_rorc_funding_per__c, oliData.gf_eoy_nfdg_trd_prpsl_rorc_per__c],
          backgroundColor: [
            'rgba(0, 68, 129, 1)',
            'rgba(25, 115, 184, 1)',
            'rgba(68, 158, 221, 1)',
            'rgba(91, 190, 255, 1)'
          ]
        }]
      },


      options: {
        legend: {
          display: false,
          position: 'top',
          labels: {
            boxWidth: 0,
            backgroundColor: 'rgba(0, 68, 129, 0)'
          }
        },
        scales: {
          yAxes: [{
            display: true,
            stacked: false,
            scaleLabel: {
              display: true,
              labelString: 'Percent (%)'
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