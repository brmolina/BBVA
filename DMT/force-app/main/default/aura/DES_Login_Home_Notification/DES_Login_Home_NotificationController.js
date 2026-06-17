({
   closeModel: function(component, event, helper) {
      // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
      component.set("v.isOpen", false);
   },
    
    closeModelHistoric: function(component, event, helper) {
      // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
      component.set("v.isOpenHistoric", false);
   },
    
   doInit : function(component, event, helper) {
       var userId = $A.get("$SObjectType.CurrentUser.Id");
       var userFirstLogin = component.get("c.returnIsFirstLogin");
       userFirstLogin.setParams({
           "userId" : userId
       });      
       userFirstLogin.setCallback(this, function(response){
           if(response.getState() === "SUCCESS"){
               component.set("v.isOpen", response.getReturnValue());
           }
       });
       $A.enqueueAction(userFirstLogin);         
   },
    
    doInitHistoric : function(component, event, helper) {
       var userId = $A.get("$SObjectType.CurrentUser.Id");
       var userFirstLoginHistoric = component.get("c.returnIsFirstLoginHistoric");
       userFirstLoginHistoric.setParams({
           "userId" : userId
       });      
       userFirstLoginHistoric.setCallback(this, function(response){
           if(response.getState() === "SUCCESS"){
               component.set("v.isOpenHistoric", response.getReturnValue());
           }
       });
       $A.enqueueAction(userFirstLoginHistoric);         
   },
    
    getDateUpdate : function(component, event, helper) {
        var dateUpdate = component.get("c.returnDateUpdate");
        dateUpdate.setCallback(this, function(response){
           if(response.getState() === "SUCCESS"){
               component.set("v.dateUpdateBooking", response.getReturnValue());
           }
       });
       $A.enqueueAction(dateUpdate);
    },
    
    getDateHistoricUpdate : function(component, event, helper){
    	var dateHisctoricUpdate = component.get("c.returnDateHistoricUpdate");
        dateHisctoricUpdate.setCallback(this, function(response){
           if(response.getState() === "SUCCESS"){
               component.set("v.dateUpdateHistoric", response.getReturnValue());
           }
       });
       $A.enqueueAction(dateHisctoricUpdate);
	}
    
})