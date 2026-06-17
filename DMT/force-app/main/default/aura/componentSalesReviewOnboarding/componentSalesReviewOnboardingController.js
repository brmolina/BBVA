({
    init : function(component, event, helper) {
        var idrecord = component.get('v.inputAttributes').recordId;
        console.log('Record id '+idrecord);
        component.set('v.recordId',idrecord);
        var flow = component.find("flowData");
        var inputVariables = [
            {
                name : "RecordStart",
                type : "String",
                value : idrecord
            }
        ];
        flow.startFlow("Post_Chatter_Asset_Review",inputVariables);
        var toast2 = $A.get("e.force:showToast");
        toast2.setParams({
            "title": "Success!",
            "message": "The Secondary Sales team has been notified and will review the form.",
            "type": 'success',
            "duration": '3000'
        });
        toast2.fire();
        window.setTimeout(
            $A.getCallback(function() {
                window.location.reload();
            }), 3000
        );
    },
})