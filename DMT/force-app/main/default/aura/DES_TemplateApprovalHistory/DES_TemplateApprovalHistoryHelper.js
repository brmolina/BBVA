({
	gotoURL : function (component) {
		var IdProcess= component.get("v.IdProcess")
    	var urlEvent = $A.get("e.force:navigateToURL");
    	urlEvent.setParams({
      "url": "/lightning/r/ProcessInstanceWorkitem/"+IdProcess+"/view"
    	});
    	urlEvent.fire();
}
})