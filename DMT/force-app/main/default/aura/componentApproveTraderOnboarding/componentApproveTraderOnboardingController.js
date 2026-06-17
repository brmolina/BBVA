({
    init : function(component, event, helper) {
        var idrec = component.get('v.inputAttributes').recordId;
        console.log('Record id '+idrec);
        component.set('v.recordId',idrec);
        var acti1 = component.get("c.approveTrader");
        // set param to method
        acti1.setParams({
            'recordId': idrec
        });
        // set a callBack
        acti1.setCallback(this, function(response2) {
            var state2 = response2.getState();
            console.log('>>>>> response2');
            console.log(response2);
            if (state2 === "SUCCESS") {
                if(response2.getReturnValue() !== 'falta') {
                    var flow = component.find("flowData");
                    // In that component, start your flow. Reference the flow's API Name.
                    var inputVariables = [
                        {
                            name : "recordId",
                            type : "String",
                            value : idrec
                        },
                        {
                            name : "traders",
                            type : "String",
                            value : response2.getReturnValue()
                        },
                    ];
                    flow.startFlow("Approve_Asset_Products",inputVariables);
                }
                window.location.reload();
            }else{
            	console.log('FALLO');
            }
        });
        $A.enqueueAction(acti1);
    }
})