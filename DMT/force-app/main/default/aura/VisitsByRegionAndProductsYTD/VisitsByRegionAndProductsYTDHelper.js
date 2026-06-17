({
  createChart : function (component) {
    console.log(':::::::createChart visitsByRegionAndProductsYTD:::::::');
    var ready = component.get("v.ready");
    if(ready === false) {
      return;
    }
    var chartCanvas = component.find("chart").getElement();
    var action = component.get("c.getData");
    action.setParams({
      "clientId": component.get("v.recordId")
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if(state === "SUCCESS") {

        var resultData = JSON.parse(response.getReturnValue());

        var resDeps = resultData.mapDepCol;
                var resDatos = resultData.mapData;

        console.log(':::::::resultData:::::::' + Object.keys(resDatos));
        var chartPrimaryLabels = [];


        if(Object.values(resDatos).length <= 0){
          component.set('v.noData', true);
        }else{
          component.set('v.noData', false);
          chartPrimaryLabels = Object.keys(resDatos);
          var chartSecondGroup = Object.values(Object.values(Object.values(resDatos)));

          var d = new Date();
          if(d.getHours() >= 0 && d.getHours() < 10){
            if(d.getMinutes() >= 0 && d.getMinutes() < 10){
              component.set("v.timeRefresh", "0" + d.getHours() + ":0" + d.getMinutes());
            }else{
              component.set("v.timeRefresh", "0" + d.getHours() + ":" + d.getMinutes());
            }
          }else{
            if(d.getMinutes() >= 0 && d.getMinutes() < 10){
              component.set("v.timeRefresh", d.getHours() + ":0" + d.getMinutes());
            }else{
              component.set("v.timeRefresh", d.getHours() + ":" + d.getMinutes());
            }
          }

          var vDatasets = [];
                    var numDeps = Object.values(resDeps).length;

                    var dataset = function (vLabel, vBackgrCol, vData){
                        return {
                            label: vLabel,
                            backgroundColor: vBackgrCol,
                            data: vData
                        }
                    }

                    if (numDeps > 0){
                       for (var j = 0; j < Object.keys(resDeps).length; j++){
                           this['listData' + Object.keys(resDeps)[j]] = [];
                           for (var i = 0; i < chartSecondGroup.length; i++){
                   this['listData' + Object.keys(resDeps)[j]].push((chartSecondGroup[i][Object.keys(resDeps)[j]]));
                  }
                           console.log('listasFams = ' + this['listData' + Object.keys(resDeps)[j]]);
                           var datasetDep = dataset (Object.keys(resDeps)[j], Object.values(resDeps)[j],this['listData' + Object.keys(resDeps)[j]]);
                           vDatasets.push(datasetDep);

                       }
                    }

          var data = {
            labels: chartPrimaryLabels,
            datasets: vDatasets
          };

          var chart = new Chart(chartCanvas,{ //NOSONAR esperando callback
            type: 'horizontalBar',
            data: data,
            options: {
              title: {
                display: true,
                text: ''
              },
              tooltips: {
                callbacks: {
                  label: function(tooltipItem, data) {
                    return baseFichaGrupo.tooltipFunction(tooltipItem, data, true, '', 0);
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

      }else if(state === "ERROR") {
        var errors = response.getError();
        if(errors){
          if(errors[0] && errors[0].message){
            console.log("Error message on createReport: " +
                  errors[0].message);
          }
        }else{
          console.log("Unknown error");
        }
      }
    });
    $A.enqueueAction(action);
  }

})