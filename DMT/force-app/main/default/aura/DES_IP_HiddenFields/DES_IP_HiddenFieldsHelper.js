({
	fetchData: function(component, event, helper) {
		return new Promise(function(resolve, reject) {
				var httpRequest = new XMLHttpRequest();

				httpRequest.onreadystatechange = $A.getCallback(function() {
					if (this.readyState === 4) { // DONE
							if (this.status >= 200 && this.status < 300) {
								component.set("v.showData", true);
								resolve();
							} else {
									var errorMsg = "";
									if (this.status === 0) {
											errorMsg = $A.get("$Label.c.DES_ERROR_IP_SERVER");
									} else {
											errorMsg = this.statusText;
									}
									component.set("v.showData", false);
									resolve();
							}
					}
				});

				helper.callConfidentialData(component, httpRequest);
		});
},
callConfidentialData: function(component, http){
		var urlEndPoint = component.get('v.endpoint');
		var objectName = component.get('v.sobjecttype');
		if(objectName == 'Opportunity') {
			urlEndPoint = urlEndPoint + $A.get("$Label.c.DES_IP_URL_OPP");
		} else if (objectName == 'dwp_kitv__Visit__c') {
			urlEndPoint = urlEndPoint + $A.get("$Label.c.DES_IP_URL_VISIT");
		}
		var externalId = component.get('v.recordId');
		var codUser = component.get('v.codUser');

		if (externalId !== null && externalId !== "") {
			urlEndPoint= urlEndPoint + externalId;
			http.open("GET", urlEndPoint, true);
			http.withCredentials = true;
			http.setRequestHeader("Content-Type", "application/json");
			http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"), codUser);
			http.send(null);
		}
	},
	getUrlIp : function(component, event, helper) {
		var actionUrl = component.get("c.urlIpServices");
		actionUrl.setCallback(this, function(response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				component.set('v.endpoint', response.getReturnValue());
				helper.fetchData(component, event, helper);
			} else {
			}
		});
		$A.enqueueAction(actionUrl);
	}
})