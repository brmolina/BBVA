({
  graficaConsulta: function(component, evolucion, parametros){
  var NomInforme = component.get("v.NombreInforme");
  var sFiltro = component.get("v.Filtro");
  var sFiltroRango = component.get("v.FiltroRango");
  var sId = component.get("v.Id");
  var action = component.get("c.getGeneraJSONReporte");
  action.setParams({
                   "sNombreReporte":NomInforme,
                   "sFiltro" : sFiltro,
                   "sFiltroRango" : sFiltroRango,
                   "sId" : sId
                   });
 
  action.setCallback(this, function(response) {
                     var state = response.getState();
                     if (state === "SUCCESS") {
                     
                     component.set("v.JsonConsultas", response.getReturnValue());
                     var reportResultData = component.get("v.JsonConsultas");
                     var concepto = [];
                     var chartData = [];
                     var chartData2 = [];
                     var chartData3 = [];
                     var chartData4 = [];
                     var chartData5 = [];
                     var nombreColumnas = [];
                     var numeroGraficaCentro = parseInt("0");
                     if(reportResultData != null){
                     for(var i=0; i<reportResultData.length; i++ ){
                     if(reportResultData.length>2){
                     for(var j=0; j<reportResultData[i].length; j++){
                     switch (i){
                     case 0:
                     concepto[j] = reportResultData[i][j] ;
                     break;
                     case 1:
                     nombreColumnas[j] = reportResultData[i][j];
                     break;
                     case 2:
                     chartData[j] = reportResultData[i][j];
                     numeroGraficaCentro = numeroGraficaCentro + parseInt(chartData[j]);
                     break;
                     case 3:
                     chartData2[j] = reportResultData[i][j];
                     break;
                     case 4:
                     chartData3[j] = reportResultData[i][j] ;
                     break;
                     case 5:
                     chartData4[j] = reportResultData[i][j];
                     break;
                     case 6:
                     chartData5[j] = reportResultData[i][j];
                     break;
                     }
                     }
                     }
                     component.set("v.conceptoList", concepto);
                     component.set("v.ParametrosDina", chartData);
                     component.set("v.ParametrosDina2", chartData2);
                     component.set("v.ParametrosDina3", chartData3);
                     component.set("v.ParametrosDina4", chartData4);
                     component.set("v.ParametrosDina5", chartData5);
                     component.set("v.labelColumnas", nombreColumnas);
                     component.set("v.numeroCentro", numeroGraficaCentro);
                     }
                     }
                     
                     
                     }
                     component.set("v.BanderaEjecucion", true);
                     });
  $A.enqueueAction(action);
  //}
  },
  dibujaGrafico : function (component, evolucion){
  var concepto = component.get("v.conceptoList");
  var bfill = component.get("v.Fill");
  var bibliotecaColor = component.get("v.Colores");
  var posicion = component.get("v.posicionLeyenda");
  var ParametrosDinamicos=[];
  var InformeName = component.get("v.NombreInforme");
 
  var scaleDes =  (InformeName==='VINCULACION')?{
        beginAtZero:true,
        min: 0,
        max: 4,
        stepSize:1
}:(InformeName==='EVOLUCION_DEUDA_SBS' || InformeName==='EVOLUCION_FACTURACION_TOTAL')?{
        beginAtZero:true,
        callback: function(valueP) {
        return 'EUR '+valueP.toFixed(2).replace(/./g, function(c, i, a) {
                                         return i && c !== "." && ((a.length - i) % 3 === 0) ? ',' + c : c;
                                         });
 }


}:{
        beginAtZero:true,
}
  ParametrosDinamicos[0] = component.get("v.ParametrosDina");
  ParametrosDinamicos[1] = component.get("v.ParametrosDina2");
  ParametrosDinamicos[2] = component.get("v.ParametrosDina3");
  ParametrosDinamicos[3] = component.get("v.ParametrosDina4");
  ParametrosDinamicos[4] = component.get("v.ParametrosDina5");
  var nombreColumnas = component.get("v.labelColumnas");
  var parametros = component.get("v.TipoGrafica");
  var numeroGraficaCentro2 = component.get("v.numeroCentro");
  var tamano = String(component.get("v.tamanoValorCentro")).length;
  var graficas = [];
  var linea100 = [];
  var valortamano;
 
  for(i=0; i < concepto.length; i++)
  {
    var colorBorder=bibliotecaColor[i];
    if (colorBorder ==='#ffffff')
    colorBorder='#676767';
    
    graficas[i]={
    type: (i==concepto.length-1 && (InformeName==='EVOLUCION_FACTURACION_TOTAL'))|| InformeName==='VINCULACION'? 'bar' : 'line',
    yAxisID: (InformeName!=='EVOLUCION_FACTURACION_TOTAL')? 'left' : (i==concepto.length-1 && InformeName=='EVOLUCION_FACTURACION_TOTAL')?'left':'right',
    label: concepto[i],
    data: ParametrosDinamicos[i],
    stacked: false,
    backgroundColor: bibliotecaColor[i],
    borderColor: colorBorder,
    borderWidth: 2,
    fill: bfill
    };
  }
 
  var i=0;
  var data = {
  labels: nombreColumnas,
  datasets: graficas,
  fill: bfill
  }
 
  //Draw Graphic
  data;
  window.myDoughnutChart = new Chart(evolucion, {
                                     type: 'bar',//parametros,
                                     data: data,                                     
                                     options: {
                                     elements: {
                                     line: {
                                        tension: (InformeName==='EVOLUCION_FACTURACION_TOTAL')? 0 : 0.4 // disables curves in line graphics
                                      }
                                    },
                                    legend: {
                                     display: true,
                                     position: posicion,
                                     fullWidth:true,
                                     reverse:false,
                                     labels: {
                                     fontColor: '#032363'
                                     },
                                     },
                                     responsive: true,                                     
                                     tooltips: {
                                     mode: 'index',
                                     intersect: false,
                                     },
                                     hover: {
                                     mode: 'nearest',
                                     intersect: true
                                     },
                                     scales: {
                                     yAxes: [{
                                             id:'left',
                                             display: true,
                                             position: 'left',
                                             scaleLabel: {
                                             display: true,
                                             labelString: 'Valor'
                                             }
                                             ,
                                             ticks:scaleDes
                                             
                                             },
                                             {
                                             id:'right',
                                             display:  (InformeName==='EVOLUCION_FACTURACION_TOTAL')? true : false,
                                             position: 'right',
                                             scaleLabel: {
                                             display: true,
                                             labelString: 'Valor'
                                             }
                                             ,
                                             ticks: {
                                               beginAtZero:true,
                                                min: 0,
                                                stepSize:1,
                                                callback: function(value) {
                                                return value + "%"
                                                }
                                             }
                                           }],
                                     xAxes: [{
                                             scaleLabel: {
                                             labelString: 'Mes'
                                             }
                                             }]
                                     }
                                     }
                                     });
  }
  })