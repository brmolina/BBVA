({
  doInit: function(component, event, helper) {
    var analysisId = component.get('v.hasRecordId');
    helper.calculateLeverage(component, analysisId);
  }
});