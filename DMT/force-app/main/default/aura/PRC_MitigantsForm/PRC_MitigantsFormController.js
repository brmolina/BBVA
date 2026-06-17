({
  onChangeExpiration : function(component, event, helper) {
    if(component.find('expirationId').get('v.value') === 'DEAL_MATURITY') {
      component.find('endDateId').set('v.value', null);
    }
    component.set('v.expirationValue', component.find('expirationId').get('v.value'));
  },
  checkData: function(component, event, helper) {
    if(helper.validFormMitigant(component, helper)) {
			helper.addMitigant(component, event, helper);
		}
  },
  changeMitiganting : function(component, event, helper) {
    helper.controlPicklist(component, component.find('mitigantingId').get('v.value'));
  },
  doViewEdit : function(component,event,helper) {
    component.set('v.externalValue', event.getParam('externalRating'));
    component.set('v.selectedValue', event.getParam('externalRating'));
    component.set('v.ratingValue', event.getParam('rating'));
    component.set('v.selectedValue1', event.getParam('rating'));
    component.set('v.pricingMitigantId', event.getParam('idMitigant'));
    console.log(component.get('v.pricingMitigantId'));
  },
  clearData: function(component, event, helper) {
			helper.emptyForm(component);
      var addMitigantEvt = $A.get("e.c:PRC_MitigantEvent");
      addMitigantEvt.fire();
  }
})