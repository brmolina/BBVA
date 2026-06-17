({
    doInit: function(cmp, event, helper) {
        helper.waiting(cmp);
        var action = cmp.get('c.getInitialData');
        action.setParams({
            'recordId': cmp.get('v.recordId')
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                console.log(result.success);
                cmp.set("v.userInfo", result.user);
                cmp.set("v.clientInfo", result.client);
                cmp.set("v.product", result.product);
                cmp.set("v.productLabel", result.productLabel);
                cmp.set("v.clientLabel", result.clientLabel);
                cmp.set("v.isCustom", result.isCustom);
                console.log(result.razonSocialLst);
                if (result.razonSocialLst === undefined) {
                    helper.showToast('Error', 'Fallo en el servidor', 'La inforamción no esta disponible. Inténtelo de nuevo mas tarde.');
                    cmp.set("v.requiredFmlMsg", 'La inforamción no esta disponible. Inténtelo de nuevo mas tarde.');
                    helper.closePanel();
                } else {
                    cmp.set('v.moreThanOne', result.moreThanOne);
                    if (!result.moreThanOne) {
                        console.log(result.razonSocialLst);
                        cmp.find("existingSubs").set("v.value", result.razonSocialLst);
                        console.log(cmp.find("existingSubs").get("v.value"));
                    }
                    cmp.set('v.razonSocialLst', result.razonSocialLst);
                    cmp.set('v.razonSocialMp', result.razonSocialMp);
                    console.log(result.razonSocialMp);
                    cmp.set("v.companyNameLabel", result.companyNameLabel);
                }
            } else if (state === 'INCOMPLETE') {
                helper.showToast('Error', 'Operación no realizada', 'Se ha producido un error al cargar la información. Inténtelo de nuevo.');
                cmp.set("v.requiredFmlMsg", 'La inforamción no esta disponible. Inténtelo de nuevo mas tarde.');
            } else if (state === 'ERROR') {
                helper.showToast('Error', 'Operación no realizada', 'Se ha producido un error al cargar la información. Inténtelo de nuevo.');
                cmp.set("v.requiredFmlMsg", 'La inforamción no esta disponible. Inténtelo de nuevo mas tarde.');
            }
            helper.doneWaiting(cmp);
        });
        $A.enqueueAction(action);
    },
    handleFieldChange: function(cmp) {
        var name = cmp.find("name").get("v.value");
        var companyName = cmp.find("existingSubs").get("v.value");
        console.log(name);
        console.log(companyName);
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
        console.log(familia);
        console.log(famMap);
        console.log(famMap[familia]);
        action.setParams({
            'dynamicPricingJSON': dynamicPricingJSON,
            'familia': familia + '',
            'familiaId': famMap[familia] + '',
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
                console.log('INCOMPLETE', state);
                helper.showToast('Error', 'Operación no realizada', 'Se ha producido un error al cargar la información. Inténtelo de nuevo.');
            } else if (state === 'ERROR') {
                console.log('ERROR', state);
                helper.showToast('Error', 'Operación no realizada', 'Se ha producido un error al cargar la información. Inténtelo de nuevo.');
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