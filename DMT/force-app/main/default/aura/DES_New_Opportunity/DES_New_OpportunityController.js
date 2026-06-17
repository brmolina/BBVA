({
    doInit : function(component, event, helper) {
      var domain = component.get("c.getDomain");
        domain.setCallback(this, function(response){
    		if(response.getState() === "SUCCESS"){
    			component.set("v.domain", response.getReturnValue());
    		}
    	});
        $A.enqueueAction(domain); 
    },

    
    aceptar : function(component, event, helper) {  
        var nameDomain = component.get("v.domain");
        window.location.replace(nameDomain+".lightning.force.com/one/one.app?source=aloha#/sObject/Account/list?filterName=Recent");
        //window.location.replace("https://bbvacibsales--ccloudd4.lightning.force.com/one/one.app?source=aloha#/sObject/Account/list?filterName=Recent");
        //helper.helperFun(component,event,'message');
    },
    cancelar : function(component, event, helper) {
        var nameDomain = component.get("v.domain");
        window.location.replace(nameDomain+".lightning.force.com/one/one.app?source=aloha#/sObject/Opportunity/list?filterName=Recent");
        //window.location.replace("https://bbvacibsales--ccloudd4.lightning.force.com/one/one.app?source=aloha#/sObject/Opportunity/list?filterName=Recent");
        //helper.helperFun(component,event,'message');
    },

})