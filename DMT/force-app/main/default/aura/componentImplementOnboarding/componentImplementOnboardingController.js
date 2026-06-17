({
    init : function(component, event, helper) {
        var idreg2 = component.get('v.inputAttributes').recordId;
        console.log('Record id '+idreg2);
        component.set('v.recordId',idreg2);
        var accion31 = component.get("c.implement");
        // set param to method
        accion31.setParams({
            'recordId': idreg2
        });
        // set a callBack
        accion31.setCallback(this, function(resp2) {
            var estatus1 = resp2.getState();
            console.log('>>>>> resp2');
            console.log(resp2);
            if (estatus1 === "SUCCESS") {
                console.log(estatus1);
                var respuesta2 = resp2.getReturnValue();
                if(respuesta2 !== "") {
                    helper.helperMethod(respuesta2, component);
                } else {
                    window.location.reload();
                }
            } else {
            	console.log('FALLO');
            }
        });
        $A.enqueueAction(accion31);
    }
})