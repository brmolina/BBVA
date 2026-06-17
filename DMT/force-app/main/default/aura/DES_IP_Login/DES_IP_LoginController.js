({
	// When a flow executes this component, it calls the invoke method
	 doInit : function(cmp, event, helpr) {
       cmp.set('v.name', Date.now());
        //Executed when component initializes
      helpr.getUrlIp(cmp, event, helpr);
  	}
})