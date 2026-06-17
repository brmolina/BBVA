({
  handleSectionToggle: function (cmp, event) {
    var openSections = event.getParam('openSections');
    if (openSections.length === 0) {
      cmp.set('v.activeSectionsMessage', "All sections are closed");
    } else {
      cmp.set('v.activeSectionsMessage', "Open sections: " + openSections.join(', '));
    }
  },
  handleTableEvent : function(component, event, helper) {
    helper.handleTableEvent(component, event, helper);
	},
  handleRevenuesEvent : function(component, event, helper) {
    helper.handleRevenues(component, event, helper);
  },
  handleCalculate : function(component, event, helper) {
    helper.handleCalculate(component, helper, null);
  },
  handleSendEmail : function(component, event, helper) {
    helper.handleTemplateBuilder(component, event, helper);
  },
  handleFirstEvent : function(component, event, helper) {
    var processed = event.getParam('dataProcessed');
    var conditionWrp = event.getParam('conditionWrp');
    var catalog = event.getParam('catalog');
    component.set('v.catalog',catalog);
    component.set('v.dataValues',JSON.parse(processed));
    helper.handleCalculate(component, helper, conditionWrp);
  },
  handleProductsSelectContinue: function(component , event ,helper ){
    helper.handleProductsSelectContinue(component,event, helper );
  }
})