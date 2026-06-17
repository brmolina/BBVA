({
    doInit: function(cmp, event, helper) {
        helper.waiting(cmp);
        var action = cmp.get('c.getInitialData');
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log(state);
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                cmp.set("v.product", result.product);
                cmp.set("v.productLabel", result.productLabel);
                cmp.set("v.clientLabel", result.clientLabel);
                cmp.set("v.isCustom", result.isCustom);
                console.log(result.razonSocialLst);
                if (result.razonSocialLst === undefined) {
                    helper.showToast('Error', 'error', ' NO SE DEVUELVEN FAMILIAS');
                    helper.closePanel();
                } else {
                    cmp.set('v.razonSocialLst', result.razonSocialLst);
                    cmp.set('v.razonSocialMp', result.razonSocialMp);
                    cmp.set("v.companyNameLabel", result.companyNameLabel);
                }
            } else if (state === 'INCOMPLETE') {
                console.log('INCOMPLETE', response);
            } else if (state === 'ERROR') {
                console.log('ERROR', response);
            }
            helper.doneWaiting(cmp);
        });
        $A.enqueueAction(action);
    },
    handleFieldChange: function(cmp) {
        var name = cmp.find("name").get("v.value");
        console.log(name);
        var companyName = cmp.find("existingSubs").get("v.value");
        if (name === '' || companyName === '' || name === null || companyName === null) {
            cmp.set('v.disableButtons', true);
        } else {
            cmp.set('v.disableButtons', false);
        }
    },
    handleOnSubmit: function(cmp, event, helper) {
        helper.waiting(cmp);
        var action = cmp.get('c.saveDynamicPricing');
        var dynamiPricing = {};
        dynamiPricing.Client__c = cmp.get('v.recordId');
        dynamiPricing.Name = cmp.find("name").get("v.value");
        dynamiPricing.Company_Name__c = cmp.get('v.recordId');
        dynamiPricing.Product__c = cmp.get('v.product');
        let dynamicPricingJSON = JSON.stringify(dynamiPricing);
        var familia = cmp.find("existingSubs").get("v.value");
        var famMap = cmp.get('v.razonSocialMp');
        var isCustom = cmp.get("v.isCustom");
        action.setParams({
            'dynamicPricingJSON': dynamicPricingJSON,
            'familia': familia,
            'familiaId': famMap[familia],
            'isCustom': isCustom
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                if (result.success) {
                    var openNewRecord = $A.get("e.force:navigateToSObject");
                    openNewRecord.setParams({
                        "recordId": result.dynamicPricingId,
                        "slideDevName": "Detail"
                    });
                    openNewRecord.fire();
                }
            } else if (state === 'INCOMPLETE') {
                console.log('INCOMPLETE', response);
            } else if (state === 'ERROR') {
                console.log('ERROR', response);
            }
            helper.doneWaiting(cmp);
        });
        $A.enqueueAction(action);
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
    },
    waiting: function(cmp) {
        cmp.set('v.waiting', true);
    },
    doneWaiting: function(cmp) {
        cmp.set('v.waiting', false);
    },
    closePanel: function(cmp, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})