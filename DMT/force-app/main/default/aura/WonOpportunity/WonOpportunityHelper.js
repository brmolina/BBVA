({
  gtData: function (component) {
    var action = component.get('c.gtData');
    action.setParams({
      'recordId': component.get('v.recordId')
    });
    action.setCallback(this, function (response) {
      if(response.getState() === 'SUCCESS') {
        component.set('v.opportunity', response.getReturnValue());
        if(component.get('v.opportunity').StageName === 'Ready to close') {
          component.set('v.readyClose', true);
        } else {
          component.set('v.readyClose', false);
        }
        component.set('v.isChecked', component.get('v.opportunity').opportunity_correct_ind_type__c);
        component.set('v.totalPotRevScale', component.get('v.opportunity').pre_oppy_revenue_next_12m_amount__c * 100 / 100);
        component.set('v.totalExpRevScale', component.get('v.opportunity').DES_Expected_Revenues__c * 100 / 100);
        var actionCurrency = component.get('c.gtCurrencyData');
        actionCurrency.setCallback(this, function (response) {
          if(response.getState() === 'SUCCESS') {
            var mapCurrencyType = response.getReturnValue();

            this.gtDataAux(component, mapCurrencyType);
          }
        });
        $A.enqueueAction(actionCurrency);
      }
    });
    $A.enqueueAction(action);
  },
  gtDataAux: function (component, mapCurrencyType) {
    if(component.get('v.opportunity').opportunity_correct_ind_type__c.CurrencyIsoCode === 'EUR'
      || component.get('v.opportunity').opportunity_correct_ind_type__c.CurrencyIsoCode === 'USD') {
        component.set('v.isMoreThan10M', component.get('v.opportunity').pre_oppy_revenue_next_12m_amount__c > 10000000);
    } else {
      var currencyAmount = mapCurrencyType[component.get('v.opportunity').CurrencyIsoCode];
      if(mapCurrencyType['USD'] > 1) {
        component.set('v.isMoreThan10M', ((component.get('v.opportunity').pre_oppy_revenue_next_12m_amount__c / currencyAmount) * mapCurrencyType['USD']) > 10000000);
      } else {
        component.set('v.isMoreThan10M', (component.get('v.opportunity').pre_oppy_revenue_next_12m_amount__c / currencyAmount) > 10000000);
      }
    }
  },
  saveOpp1: function (component) {
    var action = component.get('c.saveOpportunity');
    console.log(component.get('v.recordId'));
    action.setParams({
      'recordId': component.get('v.recordId')
    });
    action.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        console.log('ok');
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Success',
            message: 'The record has been saved successfully.',
            duration:' 5000',
            type: 'success',
            mode: 'pester'
        });
        toastEvent.fire();
        $A.get('e.force:refreshView').fire();
      } else {
        var errorMessage = JSON.stringify(response.getError()).substring(
          JSON.stringify(response.getError()).lastIndexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION, ') + ('FIELD_CUSTOM_VALIDATION_EXCEPTION, ').length,
          JSON.stringify(response.getError()).lastIndexOf(':')
        );
        var toastEventError = $A.get("e.force:showToast");
        toastEventError.setParams({
            title : 'Error',
            message: errorMessage,
            duration:'10000',
            type: 'error',
            mode: 'pester'
        });
        toastEventError.fire();
      }
    });
    $A.enqueueAction(action);
  },
})