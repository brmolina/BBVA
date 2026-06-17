({
    onInit : function(component, event, helper) {
        helper.fieldset(component, event, helper);
        helper.status(component, event, helper);
    },

    status : function(component, event, helper) {
        var actio = component.get('c.getStatus');
        var recordId = component.get('v.recordId');
        actio.setParams({
            'recordId' : recordId,
        })
        actio.setCallback(component,
            function(resp) {
                var estado = resp.getState();
                console.log('estado---------------------->'+estado);
                if (estado === 'SUCCESS'){
                console.log(resp.getReturnValue());
                var strResp = resp.getReturnValue();
                component.set("v.status", strResp);
                } else {
                console.log('FALLO : ', JSON.stringify(resp.getReturnValue()));
                }
            }
        );
        $A.enqueueAction(actio);
    },

    fieldset : function(component, event, helper) {
        var act = component.get('c.getFieldsForm');
        var recordId = component.get('v.recordId');
        act.setParams({
            'recordId' : recordId,
            'ocultar' : false
        })
        act.setCallback(component,
            function(resp) {
                var estado = resp.getState();
                console.log('estado---------------------->'+estado);
                if (estado === 'SUCCESS'){
                console.log(resp.getReturnValue());
                var strResp = resp.getReturnValue();
                component.set("v.fieldSetListAll", strResp);
                } else {
                console.log('FALLO : ', JSON.stringify(resp.getReturnValue()));
                }
            }
        );
        $A.enqueueAction(act);
    },

    assetType : function(component, event, helper) {
        var action = component.get('c.getAssetType');
        var recordId = component.get('v.recordId');
        action.setParams({
            'recordId' : recordId
        })
        action.setCallback(component,
            function(response) {
                var state = response.getState();
                console.log('state---------------------->'+state);
                if (state === 'SUCCESS'){
                console.log(response.getReturnValue());
                var storeRes = response.getReturnValue();
                component.set("v.ocultar", storeRes);
                helper.fieldsetEdit(component, event, helper);
                } else {
                console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
                }
            }
        );
        $A.enqueueAction(action);
    },

    fieldsetEdit : function(component, event, helper) {
        var action2 = component.get('c.getFieldsForm');
        var recordId = component.get('v.recordId');
        action2.setParams({
            'recordId' : recordId,
            'ocultar' : true
        })
        action2.setCallback(component,
            function(resp2) {
                var estado = resp2.getState();
                console.log('estado---------------------->'+estado);
                if (estado === 'SUCCESS'){
                console.log(resp2.getReturnValue());
                var strResp2 = resp2.getReturnValue();
                component.set("v.fieldSetList", strResp2);
                } else {
                console.log('FALLO : ', JSON.stringify(resp2.getReturnValue()));
                }
            }
        );
        $A.enqueueAction(action2);
    },

    salesInit : function(component, event, helper){
        var action2 = component.get('c.getPrimarySales');
        var recordId = component.get('v.recordId');
        action2.setParams({
            'recordId' : recordId,
        })
        action2.setCallback(component,
            function(response2) {
                var state2 = response2.getState();
                console.log('state2---------------------->'+state2);
                if (state2 === 'SUCCESS'){
                console.log(response2.getReturnValue());
                var storeRes2 = response2.getReturnValue();
                if(storeRes2[1] == null) {
                    component.set("v.value2", storeRes2[0]);
                } else {
                    component.set("v.value1", storeRes2[0]);
                    component.set("v.value2", storeRes2[1]);
                }
                } else {
                console.log('FALLO : ', JSON.stringify(response2.getReturnValue()));
                }
            }
        );
        $A.enqueueAction(action2);
    },

    saveHelper: function(component, event, helper) {
        event.preventDefault();
        var fields = event.getParam('fields');
        var assetHeader = {};
        var fieldsFields = component.get('v.fieldSetList');
        for (var i = 0; i < fieldsFields.length; i++) {
            assetHeader[fieldsFields[i].fieldAPIName] = fields[fieldsFields[i].fieldAPIName];
        }

        assetHeader['Primary_Sales__c'] = component.get("v.primaryRecord");
        assetHeader['Secondary_Sales_Id__c'] = component.get("v.secondaryRecord");
        console.log('assetHeader------------->'+JSON.stringify(assetHeader));

        var action = component.get("c.updateValues");

        action.setParams({
            'recordId': component.get('v.recordId'),
            'assetHeader': assetHeader,
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
            console.log('>>>>> SUCCESS SAVE');
            console.log('resultado-------------> '+state);
            } else {
                console.log('>>>>> ERROR SAVE');
            }
        });
        $A.enqueueAction(action);
    },

    setSalesHelper : function(component, event, helper){
        var value = event.getParam('record');
        var recordid = event.getParam('recordid');
        if(recordid === component.get('v.recordId')) {

            if(event.getParam('primary') != null) {
                component.set('v.primaryChild', event.getParam('primary'));
                component.set("v.primaryRecord", value);
            }
            if(event.getParam('secondary') != null) {
                component.set('v.secondaryChild', event.getParam('secondary'));
                component.set("v.secondaryRecord", value);
            }
            var primary = component.get('v.primaryChild');
            var secondary = component.get('v.secondaryChild');
            if(primary && secondary) {
                helper.saveHeader(component, event, helper);
            }
        }
    },

    saveHeader : function(component, event, helper) {
        if (component.get('v.saveMode')) {
            document.getElementById('submitForm').click();
        }
    },

    onHandleDelete : function(component, event, helper){
        var ventas = event.getParam("ventas");
        component.set("v.ventas", ventas);
    },

    changeSaveField : function(component, event, helper){
        var evento = event.getParam('message');
        if(evento === 'save-asset'){
            var getID = event.getParam('record');
            if (getID === component.get("v.recordId")) {
                component.set("v.saveMode", true);
            }
          }
    }
})