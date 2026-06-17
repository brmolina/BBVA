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
    refresh: function(component, event, helper){
        var iden = component.get("v.iden");
        helper.size(component, event, helper, iden);
    }
})