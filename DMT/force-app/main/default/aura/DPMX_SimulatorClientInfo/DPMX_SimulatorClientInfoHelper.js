({
    doInit: function(cmp, event, helper) {
        helper.waiting(cmp);
        var action = cmp.get('c.getData');
        action.setParams({
            'acquirerActivitiesWrapper': cmp.get('v.acquirerActivitiesWrapper'),
            'action': cmp.get('v.action'),
            'dynamicPricing': cmp.get('v.dynamicPricing')
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                cmp.set('v.dynamicPricingUpsert', result.dynamicPricingUpsert);
                cmp.set('v.initalValues', result.dynamicPricingUpsert);
                //Se invierte para que ocultar los if del cmp
                cmp.set('v.isCustom', !result.isCustom);
            } else if (state === 'INCOMPLETE') {
                console.log('INCOMPLETE', response);
            } else if (state === 'ERROR') {
                console.log('ERROR', response.getError());
            }
            helper.doneWaiting(cmp);
        });
        $A.enqueueAction(action);
    },
    handleOnSave: function(cmp, event, helper) {
        helper.waiting(cmp);
        helper.verifyyChanges(cmp);
        var action = cmp.get('c.saveData');
        action.setParams({
            'dynamicPricingUpsert': cmp.get('v.dynamicPricingUpsert'),
            'flagBool': cmp.get('v.flagBool')
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                //Refresh Simulator evt
                helper.showToast('success', $A.get('$Label.c.DPMX_Updated_Information'));
                let appEvent = $A.get('e.c:DPMX_SimulatorRefresh_evt');
                appEvent.setParams({
                    'recordId': cmp.get('v.recordId')
                });
                appEvent.fire();
                helper.destroyCmp(cmp, event, helper);
            } else if (state === 'INCOMPLETE') {
                console.log('INCOMPLETE', response);
            } else if (state === 'ERROR') {
                console.log('ERROR', response.getError());
            }
            helper.doneWaiting(cmp);
        });
        $A.enqueueAction(action);
    },
    verifyyChanges: function(cmp) {
        let flagBool = cmp.get('v.dynamicPricing.flagBool__c');
        if (flagBool != 0 && (cmp.get('v.acquirerActivitiesWrapper.transaction_y.debit.own') != cmp.get('v.dynamicPricingUpsert.Sim_Transaction_Debit_Own__c') ||
                cmp.get('v.acquirerActivitiesWrapper.transaction_y.debit.own') != cmp.get('v.dynamicPricingUpsert.Sim_Transaction_Debit_Own__c') ||
                cmp.get('v.acquirerActivitiesWrapper.billing.debit.own.currency_y') != cmp.get('v.dynamicPricingUpsert.Sim_Billing_Debit_Own_Currency__c') ||
                cmp.get('v.acquirerActivitiesWrapper.tickets.debit.own.amount') != cmp.get('v.dynamicPricingUpsert.Sim_Tickets_Debit_Own_Amount__c ') ||
                cmp.get('v.acquirerActivitiesWrapper.tickets.debit.own.currency_y') != cmp.get('v.dynamicPricingUpsert.Sim_Tickets_Debit_Own_Currency__c') ||
                cmp.get('v.acquirerActivitiesWrapper.transaction_y.debit.thirdParty') != cmp.get('v.dynamicPricingUpsert.Sim_Transaction_Debit_ThirdParty__c') ||
                cmp.get('v.acquirerActivitiesWrapper.billing.debit.thirdParty.amount') != cmp.get('v.dynamicPricingUpsert.Sim_Billing_Debit_ThirdParty_Amount__c') ||
                cmp.get('v.acquirerActivitiesWrapper.billing.debit.thirdParty.currency_y') != cmp.get('v.dynamicPricingUpsert.Sim_Billing_Debit_ThirdParty_Currency__c') ||
                cmp.get('v.acquirerActivitiesWrapper.tickets.debit.thirdParty.amount') != cmp.get('v.dynamicPricingUpsert.Sim_Tickets_Debit_ThirdParty_Amount__c') ||
                cmp.get('v.acquirerActivitiesWrapper.tickets.debit.thirdParty.currency_y') != cmp.get('v.dynamicPricingUpsert.Sim_Tickets_Debit_ThirdParty_Currency__c') ||
                cmp.get('v.acquirerActivitiesWrapper.transaction_y.credit.own') != cmp.get('v.dynamicPricingUpsert.Sim_Transaction_Credit_Own__c') ||
                cmp.get('v.acquirerActivitiesWrapper.billing.credit.own.amount') != cmp.get('v.dynamicPricingUpsert.Sim_Billing_Credit_Own_Amount__c') ||
                cmp.get('v.acquirerActivitiesWrapper.billing.credit.own.currency_y') != cmp.get('v.dynamicPricingUpsert.Sim_Billing_Credit_Own_Currency__c') ||
                cmp.get('v.acquirerActivitiesWrapper.tickets.credit.own.amount') != cmp.get('v.dynamicPricingUpsert.Sim_Tickets_Credit_Own_Amount__c') ||
                cmp.get('v.acquirerActivitiesWrapper.tickets.credit.own.currency_y') != cmp.get('v.dynamicPricingUpsert.Sim_Tickets_Credit_Own_Currency__c') ||
                cmp.get('v.acquirerActivitiesWrapper.transaction_y.credit.thirdParty') != cmp.get('v.dynamicPricingUpsert.Sim_Transaction_Credit_ThirdParty__c') ||
                cmp.get('v.acquirerActivitiesWrapper.billing.credit.thirdParty.amount') != cmp.get('v.dynamicPricingUpsert.Sim_Billing_Credit_ThirdParty_Amount__c') ||
                cmp.get('v.acquirerActivitiesWrapper.billing.credit.thirdParty.currency_y') != cmp.get('v.dynamicPricingUpsert.Sim_Billing_Credit_ThirdParty_Currency__c') ||
                cmp.get('v.acquirerActivitiesWrapper.tickets.credit.thirdParty.amount') != cmp.get('v.dynamicPricingUpsert.Sim_Tickets_Credit_ThirdParty_Amount__c') ||
                cmp.get('v.acquirerActivitiesWrapper.tickets.credit.thirdParty.currency_y') != cmp.get('v.dynamicPricingUpsert.Sim_Tickets_Credit_ThirdParty_Currency__c') ||
                cmp.get('v.acquirerActivitiesWrapper.transaction_y.international') != cmp.get('v.dynamicPricingUpsert.Sim_Transaction_International__c') ||
                cmp.get('v.acquirerActivitiesWrapper.billing.international.amount') != cmp.get('v.dynamicPricingUpsert.Sim_Billing_International_Amount__c') ||
                cmp.get('v.acquirerActivitiesWrapper.billing.international.currency_y') != cmp.get('v.dynamicPricingUpsert.Sim_Billing_International_Currency__c') ||
                cmp.get('v.acquirerActivitiesWrapper.tickets.international.amount') != cmp.get('v.dynamicPricingUpsert.Sim_Tickets_International_Amount__c') ||
                cmp.get('v.acquirerActivitiesWrapper.tickets.international.currency_y') != cmp.get('v.dynamicPricingUpsert.Sim_Tickets_International_Currency__c'))) {
            flagBool = 0;
        }
        cmp.set('v.flagBool', flagBool);
    },
    waiting: function(cmp) {
        cmp.set('v.waiting', true);
    },
    doneWaiting: function(cmp) {
        cmp.set('v.waiting', false);
    },
    showToast: function(type, message) {
        var toastEvent = $A.get('e.force:showToast');
        toastEvent.setParams({
            message: message,
            duration: 5000,
            key: 'info_alt',
            type: type,
            mode: 'dismissible'
        });
        toastEvent.fire();
    }
})