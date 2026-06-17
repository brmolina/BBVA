({
    onInit: function(component, event, helper) {
      helper.retrieveData(component, event, helper);
    },
    retrieveData: function(component, event, helper) {
      var getCountries = component.get('c.getAmountValues');
      getCountries.setParams({
        'recordId': component.get('v.localAnalysisId')
      });
      getCountries.setCallback(this, function(response) {
        if (response.getState() === 'SUCCESS') {
          console.log('Ha funcionado la llamada al getAmounts');
          component.set('v.sectionList', response.getReturnValue()[0]);
          console.log('getAmounts2 devuelve : ' + component.get("v.sectionList").total_asset_amount__c);
        } else {
          console.log('Ha fallado la llamada al getAmounts');
        }
      });
      $A.enqueueAction(getCountries);
    }
  })