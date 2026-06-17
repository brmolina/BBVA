({
  getAhaEvent: function(component, event, helper) {
    if (event.getParam('nameEvent') === 'Arc_Gen_Carousel') {
      component.set('v.view', 'false');
      if (event.getParam('IdItem') != null && event.getParam('IdItem') !== undefined) {  // eslint-disable-line
        var aha = event.getParam('IdItem');
        component.set('v.accHasAnalysisId', aha);
        component.set('v.view', 'true');
      }
    }
  }
});