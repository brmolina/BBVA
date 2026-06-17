({
    virtualNBC : function(component) {
        //LLAMO A UNA FUNCION DEL CONTROLADOR APEX PARA OBTENER LOS DATOS DE LA TEMPLATE (VirtualNBC)
        var TemplateId = component.get('v.recordId');
        var action = component.get("c.valorNBC");

        action.setParams({
            'recordId': TemplateId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log('>>>>> SUCCESS');
                component.set('v.nbc', response.getReturnValue().opportunity_id__r.gf_oppy_virtual_cmtee_ind_type__c);
                component.set('v.descr', response.getReturnValue().opportunity_nbc_comments_desc__c);
            } else {
                console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
            }
        });
        $A.enqueueAction(action);
    },
    descNBC : function(component,event) {
        var TemplateId = component.get('v.recordId');
        var descripcion = event.getParam("fields");
        console.log('------------------- fields', descripcion["opportunity_nbc_comments_desc__c"]);
        var action = component.get("c.escriboDescp");

        action.setParams({
            'recordId': TemplateId,
            'des': descripcion["opportunity_nbc_comments_desc__c"]
        });
        action.setCallback(this, function(response) {
        	var state = response.getState();
            if (state === "SUCCESS") {
                console.log('>>>>> Aitor');
                console.log('>>>>> Aitor',response.getReturnValue());
            	component.set('v.resp', response.getReturnValue());
            } else {
                console.log('>>>>> Else');
               	console.log('>>>>> Aitor',response.getReturnValue());
            	component.set('v.resp', response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    }
})