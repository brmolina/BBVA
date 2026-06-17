({
  selectRecord: function(component, event, helper) {
      var getSelectRecord = component.get('v.oRecord');
      var fieldName = component.get('v.fieldName');
      console.log('Seleccionado ------->' + JSON.stringify(getSelectRecord));
      component.set("v.outputValue", getSelectRecord[fieldName]);
      var compEvent = component.getEvent('oSelectedRecordEvent');
      compEvent.setParams({'recordByEvent' : getSelectRecord });
      compEvent.fire();
  },
  doInit: function(component,event,helper){
        console.log('init ResultCO ------->');
        var getSelectRecord = component.get('v.oRecord');
        var fieldName = component.get('v.fieldName');
        component.set("v.outputValue", getSelectRecord[fieldName]);
    },
})