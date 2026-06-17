({
    gtInitialData : function(component) {
        //LLAMO A UNA FUNCION DEL CONTROLADOR APEX PARA OBTENER LOS DATOS DE LA OPP (Name y CurrencyISOCode)
        var oppId = component.get('v.recordId');
        var action = component.get("c.gtOpportunityInfo");
        action.setParams({
            'recordId': oppId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log('>>>>> SUCCESS');
                component.set('v.isoCodeSelected', response.getReturnValue().CurrencyIsoCode);
                component.set('v.isoCodeOrig', response.getReturnValue().CurrencyIsoCode);
                component.set('v.stageName', response.getReturnValue().StageName);
            } else {
                console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
            }
        });
        // enqueue the Action
        $A.enqueueAction(action);
    },
    gtRelatedTemplate : function(component) {
        var oppId = component.get('v.recordId');
        var action = component.get("c.gtRelatedTemplate");
        action.setParams({
            'recordId': oppId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                if(response.getReturnValue() != null) {
                    component.set('v.templateId', response.getReturnValue().Id);
                    console.log('templateId', response.getReturnValue().Id);
                }

            } else {
                console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
            }
        });
        $A.enqueueAction(action);
    },
    changeISOCode : function(component) {
        console.log('>>>>> component.find("isoCodeId"): ', JSON.stringify(component.find("isoCodeId")));
        var isoCodeSelect = component.find("isoCodeId").get("v.value");
        if(isoCodeSelect !== component.get('v.isoCodeOrig')) {
            this.setVal(component, 'v.isoCodeSelected', isoCodeSelect);
            console.log('>>>>> isoCodeSelect : ', isoCodeSelect);
            var oppId = component.get('v.recordId');
            console.log('>>>>> OPP ID:  ', oppId);
            var action = component.get("c.chgOppCurrencyISOCode");
            action.setParams({
                'recordId': oppId,
                'isoCodeSelected': component.get('v.isoCodeSelected')
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set('v.message', response.getReturnValue());
                    $A.get("e.force:closeQuickAction").fire();
                    location.reload();
                } else {
                    console.log('FALLO - changeISOCode : ', JSON.stringify(response));
                }
            });
            // enqueue the Action
            $A.enqueueAction(action);
        }
    },
    setVal: function(component, field, val) {
        if (val !== undefined) {
            component.set(field, val);
        }
    },
    deleteTemplate: function(component, templateId) {
        var action = component.get("c.deleteTemplate");
        action.setParams({
            'templateId': templateId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            // console.log('>>>>> state: ', state);
            if (state === "SUCCESS") {
                console.log('Deletion completed. ');
            } else {
                console.error('EXCEPTION : ', JSON.stringify(response));
            }
        });
        // enqueue the Action
        $A.enqueueAction(action);
    }
})