({
    loadrecords: function (component) {
        return new Promise(function (resolve, reject) {
            let action = component.get('c.loadrecords');
            let oppid = component.get('v.recordId');
            let params = { 'oppid': oppid };
            let callback = function (response) {
                let state = response.getState();
                console.log('>>> state :' + state);
                let value = response.getReturnValue();
                console.log('value:' + JSON.stringify(value));
                if (state === 'SUCCESS' && value.Pricing_Details__r) {
                    console.log('>>> lista Pricing Details: ' + value.Pricing_Details__r);
                    let opp = value;
                    let priceDetails = value.Pricing_Details__r[0];
                    component.set('v.opp', opp);
                    component.set('v.priceDetails', priceDetails);
                    /* comprobación Funding Curve
                    if (priceDetails.gf_funding_curve_type__c === 'BBVA_FUNDING') {
                    component.set('v.displayFundingCost', false);
                          } else {
                    component.set('v.displayFundingCost',true);
                } */
                    /* comprobación para mostrar la sección de Amortization schedule */
                    if (priceDetails.amortization_desc__c === 'USER_DEFINED') {
                        component.set('v.isAmortizationVisible', true);
                    } else {
                        component.set('v.isAmortizationVisible', false);
                    }
                    resolve();
                } else {
                    reject();
                }
            }
            action.setParams(params);
            action.setCallback(this, callback);
            $A.enqueueAction(action);
        });
    },
    checkvisibility: function (component) {
        return new Promise(function (resolve, reject) {
            var action = component.get('c.checkvisibility');
            var opp = component.get('v.opp');
            var params = { 'opp': opp ,
                          'olis':opp.OpportunityLineItems};
            var callback = function (response) {
                var state = response.getState();
                var value = response.getReturnValue();
                if (state === 'SUCCESS') {
                    component.set('v.profitabilityloaded', value);
                    resolve('server call success!');
                } else {
                    reject('server call failed!');
                }
            };
            action.setParams(params);
            action.setCallback(this, callback);
            $A.enqueueAction(action);
        });
    },
    mitigantVisibility: function (component) {
        return new Promise(function (resolve, reject) {
            var action = component.get('c.mitigantsVisibility');
            var opp = component.get('v.opp');
            var params = { 'oppid': opp.Id };
            var callback = function (response) {
                var state = response.getState();
                var value = response.getReturnValue();
                if (state === 'SUCCESS') {
                    component.set('v.isMigitanVisible', value);
                    resolve('server call success!');
                } else {
                    reject('server call failed!');
                }
            };
            action.setParams(params);
            action.setCallback(this, callback);
            $A.enqueueAction(action);
        });
    }

})