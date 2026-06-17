({
  doInit: function (component, event, helper) {
    component.set('v.isOpen', true);
    component.set('v.recordId',component.get('v.inputAttributes').recordId);
    helper.gtData(component);
  },
  closeModal : function(component, event, helper) {
    component.set("v.isOpen", false);
  },
  markChecked: function (component, event, helper) {
    component.set('v.isChecked',component.find('checkConfirm').get('v.checked'));
  },
  saveOpp: function (component, event, helper) {
    helper.saveOpp1(component);
  }
})