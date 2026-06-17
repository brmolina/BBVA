({
  setRatingToolId: function(component, event, helper) {
    let modlSlec = component.get('v.model');
    let ratingId2020 = [{ 'label': 'ARCE corporativo 2020 INDIV', 'value': '00110008091300010002' }, { 'label': 'ARCE corporativo 2020 CONS', 'value': '00110009091300010002' }];
    let ratingId2012 = [{ 'label': 'ARCE Corporativo 2012 INDIV', 'value': '00110008091300010001' }, { 'label': 'ARCE Corporativo 2012 CONS', 'value': '00110009091300010001' }];
    let ratingOptions = modlSlec.includes('2012') ? ratingId2012 : ratingId2020;
    component.set('v.ratingTypeOptions', ratingOptions);
  }
});