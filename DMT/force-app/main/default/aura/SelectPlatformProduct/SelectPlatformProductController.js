({
  doInit: function (component, event, helper) {
    helper.getStartFields(component, event, helper);
  },
  getProduct: function (component, event, helper) {
    helper.getProduct(component, event, helper);
  },
  getTier: function (component, event, helper) {
    helper.getTier(component, event, helper);
  },
  getSelected: function (component, event, helper) {
    helper.getSelected(component, event, helper);
  },
  deleteProduct: function (component, event, helper) {
    helper.deleteProduct(component, event, helper);
  },
  cloneProduct: function (component, event, helper) {
    var butonID = 'btnEnviarFrm' + component.get('v.assetProductID');
    document.getElementById(butonID).click();
  },
  saveProduct: function (component, event, helper) {
    if (component.get('v.saveMode')) {
      helper.saveProduct(component, event, helper);
    } else {
      helper.cloneProduct(component, event, helper);
    }
  },
  handleValueChange: function (component, event, helper) {
    if (component.get('v.saveMode')) {
      var butonID = 'btnEnviarFrm' + component.get('v.assetProductID');
      document.getElementById(butonID).click();
    }
  },
  handleValueTierChange: function (component, event, helper) {
    if (component.get('v.saveTierMode') && component.get("v.isClone") === 'false') {
      var butonID1 = 'btnEnviarFrm' + component.get('v.assetProductID') + 'trader';
      document.getElementById(butonID1).click();
    }
  },
  saveProductTrader: function (component, event, helper) {
    helper.saveTierProduct(component, event, helper);
  },
})