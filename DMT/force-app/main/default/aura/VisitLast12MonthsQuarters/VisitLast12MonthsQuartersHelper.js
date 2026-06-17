({
  createChart : function(component) {
    var ready = component.get("v.ready");
    if (ready === false) {
      return;
    }
        var chartCanvas = document.getElementById("chartVisit");
    var action = component.get("c.getData");
    action.setParams({
      "clientId": component.get("v.recordId")
    });

        action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === "SUCCESS") {

        var resultData = JSON.parse(response.getReturnValue());

        var chartPrimaryLabels = [];
        var chartSecondLabels = [];
        var chartSecondData = [];

                console.log('>>>>> Object.values(resultData).length : ' + Object.values(resultData).length);
        if (Object.values(resultData).length <= 0){
          component.set('v.noData', true);
        }else{
          component.set('v.noData', false);
          chartPrimaryLabels = Object.keys(resultData);
          var chartSecondGroup = Object.values(Object.values(Object.values(resultData)));


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
          var listGCCData = [];
          var listGMData = [];
          var listGTBData = [];
          var listGFData = [];
          var listCIBData = [];
          var listFinanceData = [];

                    console.log('chartSecondGroup.length');
                    console.log(chartSecondGroup.length);
          //RECORRER Object.values(Object.values(resultData))
          for (var i = 0; i < chartSecondGroup.length; i++){
            listGCCData.push(chartSecondGroup[i]['GCC']);
            listGMData.push(chartSecondGroup[i]['GM']);
            listGTBData.push(chartSecondGroup[i]['GTB']);
            listGFData.push(chartSecondGroup[i]['IBF']);
            listCIBData.push(chartSecondGroup[i]['CIB']);
            listFinanceData.push(chartSecondGroup[i]['Finance']);
          }

          var data = {
            labels: chartPrimaryLabels,
                      pointStyle: 'line',
            datasets: [{
                          label: "GCC",
                          backgroundColor: "#20A5F2",
              data: listGCCData
            }, {
              label: "GM",
              backgroundColor: "#A4C0FF",
              data: listGMData
            }, {
              label: "GTB",
              backgroundColor: "#00358C",
              data: listGTBData
            }, {
              label: "IBF",
              backgroundColor: "#8EDEEA",
              data: listGFData
            }, {
              label: "CIB",
              backgroundColor: "#D358F7",
              data: listCIBData
            }, {
              label: "Finance",
              backgroundColor: "#F5A9F2",
              data: listFinanceData
            }]
          };

          var chart = new Chart(chartCanvas,{
            type: 'bar',
            //type: 'horizontalBar',
            data: data,
            options: {
              title: {
                display: true,
                text: ''
              },
              tooltips: {
                //displayColors: false,
                mode: 'index',
                callbacks: {
                  label: function(tooltipItem, data) {
                    return baseFichaGrupo.tooltipFunction(tooltipItem, data, false, '', 0);
                  }
                }//FIN callbacks

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