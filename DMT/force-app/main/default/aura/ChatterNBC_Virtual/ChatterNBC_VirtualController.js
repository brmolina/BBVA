({
    handleComponentEvent : function(component, event, helper) {
        var TemplateId = component.get('v.recordId');
        var action = component.get('c.gtTipoRegistro');
        var nbc = false;
        action.setParams({'iden': TemplateId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                console.log('>>>>>> SUCCESS');
                nbc = response.getReturnValue();
                helper.helperMethod(component, event, helper, nbc, TemplateId);
            } else {
                console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
            }
        });
        $A.enqueueAction(action);
    },

    insertPost : function(component, event, helper) {
        var TemplateId = component.get('v.recordId');
        var nbc = false;
        var action = component.get('c.gtTipoRegistro');
        action.setParams({'iden': TemplateId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                console.log('>>>>>> SUCCESS');
                nbc = response.getReturnValue();
                helper.helperMobile(component, event, nbc, TemplateId, helper);
            } else {
                console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
            }
        });
        $A.enqueueAction(action);
    }
})