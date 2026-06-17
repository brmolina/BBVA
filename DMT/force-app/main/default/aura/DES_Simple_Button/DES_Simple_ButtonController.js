({
	doInit : function(component, event, helper) {  
        var atributoCuenta = component.find("cuenta");
        var action = component.get("c.getAccountData");
        action.setParams({
            "accountId": component.get("v.recordId")
        });
        
        // Register the callback function
        action.setCallback(this, function(response) {
            // Set the component attributes using values returned by the API call
            	console.log(response.getState());
            	console.log(response.getReturnValue());
                component.set("v.cuenta", response.getReturnValue());  
        });
        // Invoke the service
        $A.enqueueAction(action);
        
        helper.callServerData(component, event, helper);        
    },
    
    openViewDetails : function(component, event, helper) {
        var url = component.get("v.cuenta.DES_Datamart_Link__c");
        console.log('la url es: ' + component.get("v.cuenta.DES_Datamart_Link__c"));
        window.open(url); 
       /* var urlEvent = $A.get("e.force:navigateToURL"); 
        urlEvent.setParams({ 
            "url": url }); 
        urlEvent.fire(); */

    },
    openPDF : function(component, event, helper) {
       // window.open("");
    },
    openEngloba : function(component, event, helper) {
        var url = component.get("v.cuenta.DES_Engloba_Link__c");
        console.log('la url es: ' + component.get("v.cuenta.DES_Engloba_Link__c"));
        window.open(url);
        /*var urlEvent = $A.get("e.force:navigateToURL"); 
        urlEvent.setParams({ 
            "url": url }); 
        urlEvent.fire(); */
      
    }
})