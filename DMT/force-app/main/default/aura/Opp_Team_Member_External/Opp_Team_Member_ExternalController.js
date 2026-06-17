({
  // When a flow executes this component, it calls the invoke method
  invoke : function(component, event, helper) {
    return new Promise(
        function(resolve, reject) {
          var http1 = new XMLHttpRequest();
          var operation1 = component.get('v.operation');

          var actionUrl = component.get("c.urlIpServices");
          actionUrl.setCallback(this, function(response) {
          let state = response.getState();
          if (state === "SUCCESS") {
            var urlsended =  response.getReturnValue();
            component.set('v.endpoint',urlsended);
            var url2 = urlsended;
            http1.onreadystatechange = $A
              .getCallback(function() {
                if (this.readyState === 4) { // DONE
                  if (this.status >= 200 && this.status < 300) {
                    helper.fillComponent(component, http1, operation1);
                    resolve();
                  } else {
                    var errtxt = "";
                    if (this.status === 0) {
                      errtxt = $A.get("$Label.c.DES_ERROR_IP_SERVER");
                    } else {
                      errtxt = this.statusText;
                    }
                     component.set('v.error', errtxt);
                     component.set('v.isError', true);
                     resolve();
                  }
                } else {
                }
              });
            }
          helper.selectOperation(component, operation1, url2, http1);
        });
        $A.enqueueAction(actionUrl);
        });
  }
})