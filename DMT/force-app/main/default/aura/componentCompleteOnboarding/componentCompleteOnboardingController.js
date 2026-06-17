({
    init : function(component, event, helper) {
        var idregistro1 = component.get('v.inputAttributes').recordId;
        console.log('Record id '+idregistro1);
        component.set('v.recordId',idregistro1);
        var accion1313 = component.get("c.complete");
        // set param to method
        accion1313.setParams({
            'recordId': idregistro1
        });
        // set a callBack
        accion1313.setCallback(this, function(resp) {
            var estado1 = resp.getState();
            console.log('>>>>> resp');
            console.log(resp);
            if (estado1 === "SUCCESS") {
                console.log(estado1);
                var respuesta1 = resp.getReturnValue();
                if(!respuesta1) {
                    var toast = $A.get("e.force:showToast");
                    toast.setParams({
                        "title": "Error!",
                        "message": "The form cannot be changed has been completed",
                        "type": 'error'
                    });
                    toast.fire();
                } else {
                    window.location.reload();
                }
            }else{
            	console.log('FALLO');
            }
        });
        $A.enqueueAction(accion1313);
    }
})