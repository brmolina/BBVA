({
    init : function(component, event, helper) {
        var idregist = component.get('v.inputAttributes').recordId;
        console.log('Record id '+idregist);
        component.set('v.recordId',idregist);
        var accio = component.get("c.validate");
        // set param to method
        accio.setParams({
            'recordId': idregist
        });
        // set a callBack
        accio.setCallback(this, function(resp) {
            var estatus = resp.getState();
            console.log('>>>>> resp');
            console.log(resp);
            if (estatus === "SUCCESS") {
                console.log(estatus);
                var respues = resp.getReturnValue();
                if(respues !== "") {
                    var toastEvt = $A.get("e.force:showToast");
                    if(respues === 'ErrorUserName') {
                        toastEvt.setParams({
                            "title": "Error!",
                            "message": "If the platform is Bloomberg the value All pending users in User Name field is invalid",
                            "type": 'error'
                        });
                    } else if(respues === 'error') {
                        console.log('Entro toast--------------------->');
                        toastEvt.setParams({
                            "title": "Error!",
                            "message": "You must complete the Secondary Sales",
                            "type": 'error'
                        });
                    } else if(respues === 'ssis') {
                        console.log('Entro toast 3--------------------->');
                        toastEvt.setParams({
                            "title": "Error!",
                            "message": "For the USTs product it is necessary to have the SSIs",
                            "type": 'error'
                        });
                    }  else if(respues === 'producto') {
                        console.log('Entro toast 3--------------------->');
                        toastEvt.setParams({
                            "title": "Error!",
                            "message": "At least one product must be on the form",
                            "type": 'error'
                        });
                    }  else if(respues === 'ErroreMarketSignature') {
                        toastEvt.setParams({
                            "title": "Error!",
                            "message": "You cannot move forward with this digital platform access request until the Client has signed the Signature sheet for new users.",
                            "type": 'error'
                        });
                    }  else if(respues === 'ErroreMarketAgreement') {
                        toastEvt.setParams({
                            "title": "Error!",
                            "message": "You cannot move forward with this digital platform access request until the Client has signed the BBVA eMarkets agreement.",
                            "type": 'error'
                        });
                    } else {
                        toastEvt.setParams({
                            "title": "Error!",
                            "message": "You must complete the next fields "+respues,
                            "type": 'error'
                        });
                    }
                    toastEvt.fire();
                } else {
                    window.location.reload();
                }
            }else{
            	console.log('FALLO');
            }
        });
        $A.enqueueAction(accio);
    }
})