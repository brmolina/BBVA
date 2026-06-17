({
  init : function(component,event){
    component.set("v.bGrafica",true);
  },
  filtroGrafica : function(component,event,helper){
    component.set("v.sFiltro",component.find('selFiltro').get('v.value'));
    //component.set("v.bGrafica",false); Lo comento por que no pasa el sonar y de todos modos este valor se va a pisar en la siguiente linea.
    component.set("v.bGrafica",true);
    }
})