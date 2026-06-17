({

  selectproduct: function (component, event, helper) {
    var formulario = component.find('formulario');
    formulario.submit();
  },
  aftersubmit: function (component, event, helper) {
    var loadcmpevt = component.getEvent('loadcomponentevt');
    console.log('recupero el evento:' + loadcmpevt);
    var params = {
      'componentname': 'c:PRC_PriceForm',
      'params': {
        'aura:id': 'Price Form',
        'recordId': component.get('v.recordId')
      }
    };
    console.log('seteo los parámetros : ' + JSON.stringify(params));
    loadcmpevt.setParams(params);
    loadcmpevt.fire();
    console.log('lanzo el evento');
  },
  onChangeRiskProduct: function (component, event, helper) {
    var riskProduct = component.find('riskProductId').get('v.value');
    if (riskProduct !== null || riskProduct != '') { //NOSONAR
      var listas = component.get('v.picklists');
      var n = 0;
      while (listas[n].id!=='PRODUCTS') {
          n++;
      }
      var registros = listas[n].records;
      var i = 0;
      while (registros[i].id !== riskProduct) {
          i++
      }
      var label = registros[i].name;
      component.find('riskProductName').set('v.value',label);
    }
  },
  doinit: function (component, event, helper) {
      helper.getpicklist(component, helper);
  }

})