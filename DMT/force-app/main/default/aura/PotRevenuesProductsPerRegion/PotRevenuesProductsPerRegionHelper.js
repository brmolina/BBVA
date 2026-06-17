({
  createChart : function (component) {
    var ready = component.get("v.ready");
    if (ready === false) {
      return;
    }
    var chartCanvas = component.find("chart").getElement();
    var action = component.get("c.getData");
    var family = component.get("v.familyParam");
    action.setParams({
      "clientId": component.get("v.recordId"),
      "family" : family
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var userCurrencyCode = $A.get("$Locale.currencyCode");
        var resultData = JSON.parse(response.getReturnValue());
        var chartPrimaryLabels = [];

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
          	//Family IBF:
	        var listMAData = [];
	        var listECMData = [];
	        var listLBOsData = [];
            var listPFLData = [];
            var listPFAData = [];
            var listCLData = [];
            var listSTFData = [];
            var listLMData = [];
            var listRAData = [];
            var listFCSData = [];
            //Family GM:
            var listDCMData = [];
            var listEData = [];
            var listFXData = [];
	        var listRData = [];
	        var listCData = [];
	        //Family GTB:
	        var listWCData = [];
	        var listSSData = [];
            var listCMData = [];
            var listTTFData = [];
            var listCRData = [];

          //RECORRER Object.values(Object.values(resultData))
          for (var i = 0; i < chartSecondGroup.length; i++){
            //Family IBF:
            listMAData.push(chartSecondGroup[i]['Mergers & Acquisitions']);
            listECMData.push(chartSecondGroup[i]['Equity Capital Markets']);
            listLBOsData.push(chartSecondGroup[i]['Leverage Buyout (LBOs)']);
            listPFLData.push(chartSecondGroup[i]['Project Finance - Lending']);
            listPFAData.push(chartSecondGroup[i]['Project Finance - Advisory']);
	        listCLData.push(chartSecondGroup[i]['Corporate Loans']);
          listSTFData.push(chartSecondGroup[i]['Structured Trade Finance']);
          listLMData.push(chartSecondGroup[i]['Liability Management']);
	        listRAData.push(chartSecondGroup[i]['Rating Advisory']);
	        listFCSData.push(chartSecondGroup[i]['FI capital Solutions']);
	        //Family GM:
	        listDCMData.push(chartSecondGroup[i]['Debt Capital Markets']);
	        listEData.push(chartSecondGroup[i]['Equity']);
	        listFXData.push(chartSecondGroup[i]['FX']);
            listRData.push(chartSecondGroup[i]['Rates']);
            listCData.push(chartSecondGroup[i]['Credit']);
            //Family GTB:
            listWCData.push(chartSecondGroup[i]['Working Capital']);
	        listSSData.push(chartSecondGroup[i]['Securities Services']);
	        listCMData.push(chartSecondGroup[i]['Cash Management']);
	        listTTFData.push(chartSecondGroup[i]['Transaction Trade Finance']);
	        listCRData.push(chartSecondGroup[i]['Client Resources']);
          }

                    //Family IBF:
                    var dataIBF = {
                        labels: chartPrimaryLabels,
                        datasets: [{
                                    label: "LBOs",
                                    backgroundColor: "#20A5F2",
                                    data: listLBOsData
                                   }, {
                                    label: "PFL",
                                    backgroundColor: "#A4C0FF",
                                    data: listPFLData
                                   }, {
                                    label: "PFA",
                                    backgroundColor: "#00358C",
                                    data: listPFAData
                                   }, {
                                    label: "CL",
                                    backgroundColor: "#8EDEEA",
                                    data: listCLData
                                   }, {
                                    label: "ECM",
	                                backgroundColor: "#2DCCCD",
	                                data: listECMData
                                   }, {
                                    label: "MA",
	                                backgroundColor: "#20A5F2",
	                                data: listMAData
                                   }, {
                                    label: "STF",
                                    backgroundColor: "#CAC3CF",
                                    data: listSTFData
                                   }, {
                                    label: "FCS",
                                    backgroundColor: "#D3E3F5",
                                    data: listFCSData
                                   }, {
                                    label: "RA",
                                    backgroundColor: "#028484",
                                    data: listRAData
                                   }, {
                                    label: "LM",
                                    backgroundColor: "#1BD3EB",
                                    data: listLMData
                                   }
                      ]
                       };

                    //Family GM:
                    var dataGM = {
                        labels: chartPrimaryLabels,
                        datasets: [{
                                    label: "DCM",
                                    backgroundColor: "#20A5F2",
                                    data: listDCMData
                                   }, {
                                    label: "E",
                                    backgroundColor: "#A4C0FF",
                                    data: listEData
                                   }, {
                                    label: "FX",
                                    backgroundColor: "#00358C",
                                    data: listFXData
                                   }, {
                                    label: "R",
                                    backgroundColor: "#8EDEEA",
                                    data: listRData
                                   }, {
                                    label: "C",
                                    backgroundColor: "#D358F7",
                                    data: listCData
                                   }
                      ]
                       };

                    //Family GTB:
                    var dataGTB = {
                        labels: chartPrimaryLabels,
                        datasets: [{
                                    label: "WC",
                                    backgroundColor: "#20A5F2",
                                    data: listWCData
                                   }, {
                                    label: "SS",
                                    backgroundColor: "#A4C0FF",
                                    data: listSSData
                                   }, {
                                    label: "CM",
                                    backgroundColor: "#00358C",
                                    data: listCMData
                                   }, {
                                    label: "TTF",
                                    backgroundColor: "#D358F7",
                                    data: listTTFData
                                   }, {
                                    label: "CR",
                                    backgroundColor: "#F5A9F2",
                                    data: listCRData
                                   }
                      ]
                       };
          var data;

          if (family === "IBF") {
                data = dataIBF;
            }else if (family === "GM"){
                data = dataGM;
            }else if (family === "GTB"){
                data = dataGTB;
            }


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
                    return baseFichaGrupo.tooltipFunction(tooltipItem, data, true, userCurrencyCode);
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
          component.set('v.noData', true);
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