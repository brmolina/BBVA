({
    helperMethod : function(respuesta2, component) {
        var tst2 = $A.get("e.force:showToast");
        if(respuesta2 === 'ErrorUserName') {
            tst2.setParams({
                "title": "Error!",
                "message": "If the platform is Bloomberg the value All pending users in User Name field is invalid",
                "type": 'error'
            });
        } else if(respuesta2 === 'ErrorMarkitPermission') {
            tst2.setParams({
                "title": "Error!",
                "message": "You must confirm we have Markitwire permissions before moving on to the next phase.",
                "type": 'error'
            });
        } else if(respuesta2 === 'ErrorMarkitMurex') {
            tst2.setParams({
                "title": "Error!",
                "message": "You must confirm the STP Markitwire-Murex is in place before moving on to the next phase.",
                "type": 'error'
            });
        } else if(respuesta2 === 'ErrorMarkitWire') {
            tst2.setParams({
                "title": "Error!",
                "message": "Because the client does not confirm via Markitwire, the eSales team is setting up "
                +"a drop copy in Markitwire and will take the form to the next step once ready.",
                "type": 'error'
            });
        } else if(respuesta2 === 'ErroreMarketSignature') {
            tst2.setParams({
                "title": "Error!",
                "message": "You cannot move forward with this digital platform access request until the Client has signed the Signature sheet for new users.",
                "type": 'error'
            });
        } else if(respuesta2 === 'ErroreMarketAgreement') {
            tst2.setParams({
                "title": "Error!",
                "message": "You cannot move forward with this digital platform access request until the Client has signed the BBVA eMarkets agreement.",
                "type": 'error'
            });
        } else if(respuesta2 === 'producto') {
            console.log('Entro tst2 3--------------------->');
            tst2.setParams({
                "title": "Error!",
                "message": "At least one product must be on the form",
                "type": 'error'
            });
        } else if(respuesta2 === 'ssis') {
            console.log('Entro tst2 3--------------------->');
            tst2.setParams({
                "title": "Error!",
                "message": "For the USTs product it is necessary to have the SSIs",
                "type": 'error'
            });
        } else if(respuesta2 === 'flow') {
            //var flow = component.find("flowData");
            // In that component, start your flow. Reference the flow's API Name.
            var flow = component.find("flowData");
            var inputVariables = [
                {
                    name : "recordId",
                    type : "String",
                    value : idregistro2
                }
            ];
            flow.startFlow("Post_Chatter_Asset_Implement",inputVariables);
            window.location.reload();
        } else {
            tst2.setParams({
                "title": "Error!",
                "message": "You must complete the next fields "+respuesta2,
                "type": 'error'
            });
        }
        tst2.fire();
    }
})