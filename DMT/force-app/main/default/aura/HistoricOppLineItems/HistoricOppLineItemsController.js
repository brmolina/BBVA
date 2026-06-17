({
  doInit : function(component, event, helper) {
    helper.fetchProductsOpp(component, event);
  },
  navigateRecord: function(component, event, helper) {
    var target = event.target.id;
    var oppId = target.split('.||.')[0];
    var oppLineId = target.split('.||.')[1];
    var pageReference = {
      type: 'standard__component',
      attributes: {
          componentName: 'c__historicOppProductDetails',
      },
      state: {
          "c__oppLineId": oppLineId,
          "c__oppId": oppId
      }
    };
    var navService = component.find("navService");
    event.preventDefault();
    navService.navigate(pageReference);
  }
})