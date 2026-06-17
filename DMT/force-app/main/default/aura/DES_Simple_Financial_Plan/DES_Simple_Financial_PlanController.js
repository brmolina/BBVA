({
	doInit : function(component, event, helper) {   
		//alert('v. 01.08');
        //alert('>1> ' + $A.get("$Label.c.DES_Figures_shown"));
        var labelWithoutCurrency = $A.get("$Label.c.DES_Figures_shown");
        labelWithoutCurrency = labelWithoutCurrency.substring(0, labelWithoutCurrency.length-3);
        //alert('>2> ' + labelWithoutCurrency);
		component.set("v.textFiguresShow", labelWithoutCurrency);
        //alert('> showCurrency: ' + component.get("v.showCurrency"));
        // Retrieve contacts during component initialization
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
    }
})