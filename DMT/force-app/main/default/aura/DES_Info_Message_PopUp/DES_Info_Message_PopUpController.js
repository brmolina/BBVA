({
closeModel: function(component, event, helper) {
      // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
      component.set("v.isOpen", false);
   },
    doInit: function(component, event, helper) {
        var onlyOnce= component.get("v.onlyOnce");
        if(onlyOnce){
            var minutes = component.get("v.cookieLifetime");
            var recordId = component.get("v.recordId");
            var mostrarPopup = helper.checkCookie(recordId, minutes);
            if(mostrarPopup){
                component.set("v.isOpen", false);
            }
    	}
	}
})