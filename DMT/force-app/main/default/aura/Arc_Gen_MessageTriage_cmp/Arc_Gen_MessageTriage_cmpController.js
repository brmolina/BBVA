({
  onInit: function(component, event, helper) {
    // Get the empApi component
    const empApi = component.find('empApi');

    // Uncomment below line to enable debug logging (optional)
    empApi.setDebugFlag(true);

    // Register error listener and pass in the error handler function
    empApi.onError($A.getCallback(error => {
      // Error can be any type of error (subscribe, unsubscribe...)
      console.error('EMP API error: ', error);
    }));
    helper.getArceData(component, event, helper);
  }
});