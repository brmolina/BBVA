({
    init : function(component, event, helper) {
        var idrec = component.get('v.inputAttributes').recordId;
        console.log('Record id '+idrec);
        component.set('v.recordId',idrec);
        var accion = component.get("c.approve");
        // set param to method
        accion.setParams({
            'recordId': idrec
        });
        // set a callBack
        accion.setCallback(this, function(respuesta) {
            var estado = respuesta.getState();
            console.log('>>>>> respuesta');
            console.log(respuesta);
            if (estado === "SUCCESS") {
                console.log(estado);
                window.location.reload();
            }else{
            	console.log('FALLO');
            }
        });
        $A.enqueueAction(accion);
    }
})