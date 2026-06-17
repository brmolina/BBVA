({
    init : function(component, event, helper) {
        var idrecord5 = component.get('v.inputAttributes').recordId;
        console.log('Record id '+idrecord5);
        component.set('v.recordId',idrecord5);
        var flow5 = component.find("flowData");
        // In that component, start your flow5. Reference the flow5's API Name.
        var inputVariables = [
            {
                name : "recordId",
                type : "String",
                value : idrecord5
            }
        ];
        flow5.startFlow("Wrong_Data_E_commerce_Registry",inputVariables);
    },

    changeStatus : function (component, event) {
        if (event.getParam('status') === "FINISHED") {
            window.location.reload();
        }
    },

    closeModalFlow : function (component, event) {
        $A.get("e.force:closeQuickAction").fire();
        $A.get("e.force:refreshView").fire();
    },
})