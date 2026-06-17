({
  onUpdate: function(component, event, helper) {
    const fields = component.get('v.ahaFields');
    if (fields && fields.arce__current_proposed_amount__c) {
      component.set('v.value', fields.arce__current_proposed_amount__c);
    }
  }
});