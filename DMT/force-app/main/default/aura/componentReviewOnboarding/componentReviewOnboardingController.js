({
    init : function(component, event, helper) {
        var idreg = component.get('v.inputAttributes').recordId;
        console.log('Record id '+idreg);
        component.set('v.recordId',idreg);
        var act1 = component.get("c.review");
        // set param to method
        act1.setParams({
            'recordId': idreg
        });
        // set a callBack
        act1.setCallback(this, function(respu) {
            var stado = respu.getState();
            console.log('>>>>> respu');
            console.log(respu);
            if (stado === "SUCCESS") {
                console.log(stado);
                var respuesta = respu.getReturnValue();
                console.log('--------------------->'+respuesta);
                if(respuesta === 'error') {
                    console.log('Entro toast--------------------->');
                    var tstEv = $A.get("e.force:showToast");
                    tstEv.setParams({
                        "title": "Error!",
                        "message": "You must complete the Secondary Sales",
                        "type": 'error'
                    });
                    tstEv.fire();
                } else if(respuesta === 'ErrorUserName') {
                    console.log('Entro toast 2--------------------->');
                    var tstEvt1= $A.get("e.force:showToast");
                    tstEvt1.setParams({
                        "title": "Error!",
                        "message": "If the platform is Bloomberg the value All pending users in User Name field is invalid",
                        "type": 'error'
                    });
                    tstEvt1.fire();
                } else if(respuesta === 'producto') {
                    console.log('Entro toast 3--------------------->');
                    var tstEvt2= $A.get("e.force:showToast");
                    tstEvt2.setParams({
                        "title": "Error!",
                        "message": "At least one product must be on the form",
                        "type": 'error'
                    });
                    tstEvt2.fire();
                } else {
                    var flow = component.find("flowData");
                    var inputVariables = [
                        {
                            name : "RecordStart",
                            type : "String",
                            value : idreg
                        }
                    ];
                    flow.startFlow("Post_Chatter_Asset_Review",inputVariables);
                    window.location.reload();
                }

            }else{
            	console.log('FALLO');
            }
        });
        $A.enqueueAction(act1);
    }
})