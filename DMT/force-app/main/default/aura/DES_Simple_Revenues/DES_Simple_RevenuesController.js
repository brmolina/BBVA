({
	doInit : function(component, event, helper) {   
  /*      var today = new Date();
        var mes = '';
        var monthDigit = today.getMonth() + 1;
        if (monthDigit == 1) mes = 'Jan';     
        else if(monthDigit == 2) mes = 'Feb';
        else if(monthDigit == 3) mes = 'Mar';
        else if(monthDigit == 4) mes = 'Apr';
        else if(monthDigit == 5) mes = 'May';
        else if(monthDigit == 6) mes = 'Jun';
        else if(monthDigit == 7) mes = 'Jul';
        else if(monthDigit == 8) mes = 'Aug';
        else if(monthDigit == 9) mes = 'Sept';
        else if(monthDigit == 10) mes = 'Oct';
        else if(monthDigit == 11) mes = 'Nov';
        else if(monthDigit == 12) mes = 'Dec';           		
        
        component.set('v.today', mes + " " + today.getFullYear().toString().substr(-2));*/

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