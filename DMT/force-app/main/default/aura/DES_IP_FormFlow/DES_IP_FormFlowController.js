({
	// When a flow executes this component, it calls the invoke method
	invoke : function(component, event, helper) {
		return new Promise(
				function(resolve, reject) {
					var http = new XMLHttpRequest();
					var operation = component.get('v.operation');
					var url = component.get('v.endpoint');
					http.onreadystatechange = $A
							.getCallback(function() {
								if (this.readyState === 4) { // DONE
									if (this.status >= 200 && this.status < 300) {
										helper.fillComponent(component, http,operation);
										resolve();
									} else {
										var errorText = "";
										if (this.status === 0) {
											errorText = $A.get("$Label.c.DES_ERROR_IP_SERVER");
										} else {
											errorText = this.statusText;
										}
                                        component.set('v.error', errorText);
										reject(new Error(errorText));
									}
								}
							});

					helper.selectOperation(component, operation, url, http);
				});
	}
})