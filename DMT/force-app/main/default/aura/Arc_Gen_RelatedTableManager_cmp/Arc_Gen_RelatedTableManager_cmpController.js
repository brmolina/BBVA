({
  doInit: function(component, event, helper) {
    let curencyList = [
      {'label': 'MXN', 'value': 'MXN'},
      {'label': 'EUR', 'value': 'EUR'},
      {'label': 'USD', 'value': 'USD'},
    ];
    let unitList = [
      {'label': $A.get('$Label.c.Arc_Gen_Unit'), 'value': '1'},
      {'label': $A.get('$Label.c.Arc_Gen_Thousands'), 'value': '2'},
      {'label': $A.get('$Label.c.Arc_Gen_Millions'), 'value': '3'},
    ];
    component.set('v.currencyLts', curencyList);
    component.set('v.unitLts', unitList);
    helper.combosValue(component, event, helper);
  },
  handleChangeCur: function(component, event, helper) {
    var currVal = event.getParam('value');
    helper.saveCombos(component, event, helper, currVal, 'currency');
  },
  handleChangeUnit: function(component, event, helper) {
    var unitVal = event.getParam('value');
    helper.saveCombos(component, event, helper, unitVal, 'unit');
  }
});