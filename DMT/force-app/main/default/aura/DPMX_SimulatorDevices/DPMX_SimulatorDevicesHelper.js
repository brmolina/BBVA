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
            console.log('IN');
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                cmp.set('v.dynamicPricingUpsert', result.dynamicPricingUpsert);
                cmp.set('v.checkboxesWrapper', result.checkboxesWrapper);
                console.log(result.checkboxesWrapper);
                cmp.set('v.isCustom', result.isCustom);
            } else if (state === 'INCOMPLETE') {
                console.log('INCOMPLETE', response);
            } else if (state === 'ERROR') {
                console.log('ERROR', response.getError());
            }
            helper.doneWaiting(cmp);
        });
        $A.enqueueAction(action);
    },
    handleOnCheckTerminal: function(cmp, event, helper) {
        if (event.getSource().get("v.checked")) {
            cmp.set('v.checkboxesWrapper.terminalIdCheckbox', true);
        } else {
            cmp.set('v.checkboxesWrapper.terminalIdCheckbox', false);
        }
    },
    handleOnCheckPinpad: function(cmp, event, helper) {
        if (event.getSource().get("v.checked")) {
            cmp.set('v.checkboxesWrapper.pinPadsInfoPinPadsCheckbox', true);
        } else {
            cmp.set('v.checkboxesWrapper.pinPadsInfoPinPadsCheckbox', false);
        }
    },
    handleOnCheckRecCharg: function(cmp, event, helper) {
        if (event.getSource().get("v.checked")) {
            cmp.set('v.checkboxesWrapper.RecurringChargesCheckbox', true);
        } else {
            cmp.set('v.checkboxesWrapper.RecurringChargesCheckbox', false);
        }
    },
    handleOnCheckPOS: function(cmp, event, helper) {
        if (event.getSource().get("v.checked")) {
            cmp.set('v.checkboxesWrapper.posCheckbox', true);
        } else {
            cmp.set('v.checkboxesWrapper.posCheckbox', false);
        }
    },
    handleOnSave: function(cmp, event, helper) {
        var withPinPadBool = false;
        var withoutPinPadBool = false;
        if (cmp.get('v.dynamicPricingUpsert').Sim_PinPadsInfo_PinPads__c > 0) {
            withPinPadBool = true;
        }
        if (cmp.get('v.dynamicPricingUpsert').pinPadsInfo_withoutPinPads__c > 0) {
            withoutPinPadBool = true;
        }
        console.log(withoutPinPadBool);
        console.log(withPinPadBool);
        if (withPinPadBool && withoutPinPadBool) {
            helper.showToast('ERROR', 'Valores incorrectos.', 'Has agregado valores para ambos pinpads.');
        } else {
            helper.waiting(cmp);
            helper.verifyChangesDevices(cmp);
            helper.verifyChangesCommissions(cmp);
            var action = cmp.get('c.saveData');
            console.log(cmp.get('v.dynamicPricingUpsert').Sim_Fees_ExtraBilling_Amount__c);
            console.log(cmp.get('v.dynamicPricingUpsert').Sim_Fees_Cellnet_Amount__c);
            console.log(cmp.get('v.dynamicPricingUpsert').Sim_Fees_Billing_Amount__c);
            action.setParams({
                'dynamicPricingUpsert': cmp.get('v.dynamicPricingUpsert'),
                'acquirerActivitiesWrapper': cmp.get('v.acquirerActivitiesWrapper'),
                'checkboxesWrapper': cmp.get('v.checkboxesWrapper'),
                'flagBool': cmp.get('v.flagBool'),
                'isCustom': cmp.get('v.isCustom')
            })
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === 'SUCCESS') {
                    var result = response.getReturnValue();
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
        }

    },
    "verifyChangesDevices": function(cmp) {
        let flagBool = cmp.get('v.dynamicPricing.flagBool__c');
        let hasChanges = true;
        if (flagBool != 0 && ((cmp.get('v.acquirerActivitiesWrapper.terminal.id_y') != 0 && cmp.get('v.acquirerActivitiesWrapper.terminal.id_y') != null) != cmp.get('v.checkboxesWrapper.terminalIdCheckbox')) ||
            cmp.get('v.acquirerActivitiesWrapper.terminal.id_y') != cmp.get('v.dynamicPricingUpsert.Sim_Terminal_Id__c') ||
            ((cmp.get('v.acquirerActivitiesWrapper.devices.pinPads.pinPadsNumber') != 0 && cmp.get('v.acquirerActivitiesWrapper.devices.pinPads.pinPadsNumber') != null) != cmp.get('v.checkboxesWrapper.pinPadsInfoPinPadsCheckbox')) ||
            cmp.get('v.acquirerActivitiesWrapper.devices.pinPads.pinPadsNumber') != cmp.get('v.dynamicPricingUpsert.Sim_PinPadsInfo_PinPads__c') ||
            cmp.get('v.acquirerActivitiesWrapper.ecommerceCheckbox') != cmp.get('v.dynamicPricingUpsert.Sim_Ecommerce__c')) {
            flagBool = 0;
        } else {
            hasChanges = false;
        }
        cmp.set('v.hasChanges', hasChanges);
        cmp.set('v.flagBool', flagBool);

    },
    "verifyChangesCommissions": function(cmp) {
        let flagBool = cmp.get('v.dynamicPricing.flagBool__c');
        let hasChanges = cmp.get('v.hasChanges');
        if (!hasChanges) {
            if (flagBool != 1 && (cmp.get('v.checkboxesWrapper.feesExtraBillingAmountCheckbox') != (cmp.get('v.acquirerActivitiesWrapper.commission.extraBilling.amount') != 0 && cmp.get('v.acquirerActivitiesWrapper.commission.extraBilling.amount') != null) ||
                    cmp.get('v.checkboxesWrapper.feesCellnetAmountCheckbox') != (cmp.get('v.acquirerActivitiesWrapper.commission.cellnet.amount') != 0 && cmp.get('v.acquirerActivitiesWrapper.commission.cellnet.amount') != null) ||
                    cmp.get('v.checkboxesWrapper.feesBillingAmountCheckbox') != (cmp.get('v.acquirerActivitiesWrapper.commission.billing.amount') != 0 && cmp.get('v.acquirerActivitiesWrapper.commission.billing.amount') != null)
                )) {
                flagBool = 1;
            } else {
                flagBool = 0;
            }
        }
        cmp.set('v.flagBool', flagBool);
    },
    waiting: function(cmp) {
        cmp.set('v.waiting', true);
    },
    doneWaiting: function(cmp) {
        cmp.set('v.waiting', false);
    },
    showToast: function(type, title, message) {
        var toastEvent = $A.get('e.force:showToast');
        toastEvent.setParams({
            title: title,
            message: message,
            duration: 5000,
            key: 'info_alt',
            type: type,
            mode: 'dismissible'
        });
        toastEvent.fire();
    }
})