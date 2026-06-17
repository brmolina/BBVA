({
  doInit : function(component, event, helper) {
    component.set('v.myColumns', [
    { label: 'Business Line', fieldName: 'businessLine', type: 'string', typeAttributes: { label: { fieldName: 'businessLine' } }, cellAttributes:  {alignment: 'center'}},
    { label: 'Rates', fieldName: 'rates', type: 'string', typeAttributes: { label: { fieldName: 'rates' } }, cellAttributes:  {alignment: 'center'}},
    { label: 'Credit', fieldName: 'credit', type: 'string', typeAttributes: { label: { fieldName: 'credit' } }, cellAttributes:  {alignment: 'center'}},
    { label: 'FX', fieldName: 'fxProduct', type: 'string', typeAttributes: { label: { fieldName: 'fxProduct' } }, cellAttributes:  {alignment: 'center'}},
    { label: 'Equity', fieldName: 'equity', type: 'string', typeAttributes: { label: { fieldName: 'equity' } }, cellAttributes:  {alignment: 'center'}},
    { label: 'Other', fieldName: 'other', type: 'string', typeAttributes: { label: { fieldName: 'other' } }, cellAttributes:  {alignment: 'center'}},
    { label: 'CVA', fieldName: 'cva', type: 'string', typeAttributes: { label: { fieldName: 'cva' } }, cellAttributes:  {alignment: 'center'}},
    { label: 'Matfil', fieldName: 'matfil', type: 'string', typeAttributes: { label: { fieldName: 'matfil' } }, cellAttributes:  {alignment: 'center'}},
    { label: 'XB', fieldName: 'xsell', type: 'string', typeAttributes: { label: { fieldName: 'xsell' } }, cellAttributes:  {alignment: 'center'}},
    { label: 'TOTAL', fieldName: 'total', type: 'string', typeAttributes: { label: { fieldName: 'total' } }, cellAttributes:  {alignment: 'center'}},
  ]);
   var accountId = component.get('v.recordId');
  var franchiseValues = component.get('c.returnFracnhise');
  franchiseValues.setParams({
    'accountId': accountId
  });
    franchiseValues.setCallback(this, function (response) {
        var state = response.getState();
          if (state === "SUCCESS") {
              component.set("v.FrList", response.getReturnValue());
        console.log(response.getReturnValue());
          }
      });
      $A.enqueueAction(franchiseValues);
        component.set('v.myColumnsM', [
    { label: 'Business Line', fieldName: 'businessLine', type: 'string', typeAttributes: { label: { fieldName: 'businessLine' } }, cellAttributes:  {alignment: 'center'}},
    { label: 'Rates', fieldName: 'rates', type: 'string', typeAttributes: { label: { fieldName: 'rates' } }, cellAttributes:  {alignment: 'center'}},
    { label: 'Credit', fieldName: 'credit', type: 'string', typeAttributes: { label: { fieldName: 'credit' } }, cellAttributes:  {alignment: 'center'}},
    { label: 'FX', fieldName: 'fxProduct', type: 'string', typeAttributes: { label: { fieldName: 'fxProduct' } }, cellAttributes:  {alignment: 'center'}},
    { label: 'Equity', fieldName: 'equity', type: 'string', typeAttributes: { label: { fieldName: 'equity' } }, cellAttributes:  {alignment: 'center'}},
    { label: 'Other', fieldName: 'other', type: 'string', typeAttributes: { label: { fieldName: 'other' } }, cellAttributes:  {alignment: 'center'}},
    { label: 'CVA', fieldName: 'cva', type: 'string', typeAttributes: { label: { fieldName: 'cva' } }, cellAttributes:  {alignment: 'center'}},
    { label: 'Matfil', fieldName: 'matfil', type: 'string', typeAttributes: { label: { fieldName: 'matfil' } }, cellAttributes:  {alignment: 'center'}},
    { label: 'XB', fieldName: 'xsell', type: 'string', typeAttributes: { label: { fieldName: 'xsell' } }, cellAttributes:  {alignment: 'center'}},
    { label: 'TOTAL', fieldName: 'total', type: 'string', typeAttributes: { label: { fieldName: 'total' } }, cellAttributes:  {alignment: 'center'}},
  ]);
   var accountId = component.get('v.recordId');//NOSONAR
  var franchiseValuesM = component.get('c.returnFracnhiseM');
  franchiseValuesM.setParams({
    'accountId': accountId
  });
    franchiseValuesM.setCallback(this, function (response) {
        var state = response.getState();
          if (state === "SUCCESS") {
              component.set("v.FrListM", response.getReturnValue());
        console.log(response.getReturnValue());
          }
      });
      $A.enqueueAction(franchiseValuesM);
  }
})