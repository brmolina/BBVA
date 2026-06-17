({
    init : function(component, event, helper) {

        var idrecord = component.get('v.inputAttributes').recordId;
        console.log('Record id '+idrecord);
        var appEvent = $A.get("e.c:AssetAddProdEvent");
        appEvent.setParams({
            "message" : 'add-product',
            "record" : idrecord

            });
        appEvent.fire();
    }
})