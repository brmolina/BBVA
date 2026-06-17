({
    doInit : function(component, event, helper) {
        var url = $A.get("$Label.c.DES_AARequestUrl");
        window.open(url,'_blank');    
    }
})