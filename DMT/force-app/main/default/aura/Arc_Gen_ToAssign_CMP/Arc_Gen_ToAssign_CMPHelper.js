({
  setValidation: function(component, element, value) {
    var validations = component.get('v.validations');
    validations[element] = value;
    component.set('v.validations', validations);
  }
});