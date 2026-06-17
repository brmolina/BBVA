({
  doInit: function(component, event, helper) {
    const availableArceTypes = component.get('v.availableArceTypes');
    const arceTypesObject = {};

    for (var arceType of availableArceTypes) {
      arceTypesObject[arceType] = true;
    }

    component.set('v.isArceTypeEnabled', arceTypesObject);
  },

  changeArceSelection: function(component, event, helper) {
    var arceTypeChangeEvent = component.getEvent('arceTypeChangeEvent');
    arceTypeChangeEvent.setParams({
      eventType: 'arceTypeChanged',
      parameters: { arceType: event.target.value }
    });
    arceTypeChangeEvent.fire();
  }
});