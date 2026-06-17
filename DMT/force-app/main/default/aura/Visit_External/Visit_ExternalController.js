({
  // When a flow executes this component, it calls the invoke method
  invoke : function(component, event, helper) {
    return new Promise(
        function(resolve, reject) {
          var http2 = new XMLHttpRequest();
          var operationtype = component.get('v.operation');
          var url3 = component.get('v.endpoint');
          http2.onreadystatechange = $A
              .getCallback(function() {
                if (this.readyState === 4) { // DONE
                  if (this.status >= 200 && this.status < 300) {
                    helper.fillComponent(component, http2,operationtype);
                    resolve();
                  } else {
                    var errtext = "";
                    if (this.status === 0) {
                      errtext = $A.get("$Label.c.DES_ERROR_IP_SERVER");
                    } else {
                      errtext = this.statusText;
                    }                      
                    component.set('v.error',errtext);
                    component.set('v.isError',true);
                    resolve();
                  }
                }
              });

          helper.selectOperation(component, operationtype, url3, http2);
        });
  }
})