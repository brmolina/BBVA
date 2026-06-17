({
    init : function(component, event, helper) {
        var idrecord3 = component.get('v.inputAttributes').recordId;
        console.log('Record id '+idrecord3);
        component.set('v.recordId',idrecord3);
        var flow2 = component.find("flowData");
        // In that component, start your flow2. Reference the flow2's API Name.
        var inputVariables = [
            {
                name : "recordId",
                type : "String",
                value : idrecord3
            }
        ];
        flow2.startFlow("Reject_Asset_Products",inputVariables);
    },

    statusChange : function (component, event) {
        if (event.getParam('status') === "FINISHED") {
            window.location.reload();
        }
    },

    closeFlowModal : function (component, event) {
        $A.get("e.force:closeQuickAction").fire();
        $A.get("e.force:refreshView").fire();
    },
})