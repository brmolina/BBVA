({
    doInit : function(component, event, helper) {
        var eUrl= $A.get("e.force:navigateToURL");
        eUrl.setParams({     
            "url": 'https://cibdesktop.es.igrupobbva/AMIWEB/amiweb/Iframe?iframe=CALCRAR_MVC'    
        });    
        eUrl.fire();     
    }
})