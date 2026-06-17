({
  hinit: function(component, event) {
    var a = component.get('c.getProductsActive');
    a.setCallback(this, function(response) {
      let state = response.getState();
      if (state === 'SUCCESS') {
        var respuesta = response.getReturnValue();
        component.set('v.listProducts', respuesta);
        component.set('v.spinnerStatus', false);
        if (respuesta.length < 1) {
          component.set('v.error', true);
        }
      }
    });
    $A.enqueueAction(a);
  },
  honSubmit: function(component, event) {
    var fields = event.getParam('fields');
    fields.arce__account_has_analysis_id__c = component.get('v.recordId');
    fields.arce__Product_id__c = component.get('v.selectedChild');
    fields.RecordTypeId = component.get('v.recordTypeId');
    this.putZero(fields);
    component.find('myform').submit(fields);
  },
  putZero: function(fields) {
    var fieldExp = ['arce__banrel_current_limit_name__c', 'arce__banrel_commitment_name__c',
      'arce__banrel_uncommitment_name__c', 'arce__banrel_outstanding_name__c'];
    for (var i = 0; i < fieldExp.length; i++) {
      for (var fiel in fields) {
        if (fiel === fieldExp[i] && (fields[fiel] < 0 || !fields[fiel])) {
          fields[fiel] = 0;
        }
      }
    }
  },
  showToast: function(type, message) {
    var toastEventUE = $A.get('e.force:showToast');
    toastEventUE.setParams({
      'title': '',
      'type': type,
      'message': message
    });
    toastEventUE.fire();
  },
});