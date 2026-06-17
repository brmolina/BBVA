({
	selectOperation : function(component, operationtype, url, http) {
        var visitOwner = component.get('v.visitOwner');
        var codVisit = component.get('v.codVisit');
        var visitStatus = component.get('v.visitStatus');
        var visitLocation = component.get('v.visitLocation');
        if (operationtype === 'alta') {

            const visitData = {
                visitStatus : visitStatus,
                visitLocation : visitLocation,
                visitOwner : visitOwner,
                codVisit : codVisit
            };

            url = url + $A.get("$Label.c.DES_IP_URL_VISIT");

            http.open("POST", url, true);
            http.withCredentials = true;
            http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"),
                                  visitOwner);
            http.setRequestHeader("Content-Type", "application/json");
            http.send(JSON.stringify(visitData));

        } else if (operationtype === 'consulta') {

            url = url + $A.get("$Label.c.DES_IP_URL_VISIT") + codVisit;
            http.open("GET", url, true);
            http.withCredentials = true;
            http.setRequestHeader("Content-Type", "application/json");
            http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"),
                                  visitOwner);
            http.send(null);

        } else if (operationtype === 'borrado') {

            url = url + $A.get("$Label.c.DES_IP_URL_VISIT") + codVisit + "?_method=DELETE";

            http.open("POST", url, true);
            http.withCredentials = true;
            http.setRequestHeader("Content-Type", "application/json");
            http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"),
                                  visitOwner);
            http.send(null);
        }
    },
    fillComponent : function(component, http, operation) {
        if (operation === 'consulta') {
          	if (http.responseText != null) {

        		var response = JSON.parse(http.responseText);
       			component.set('v.visitOwner', response.visitOwner);
              	component.set('v.visitStatus', response.visitStatus);
              	component.set('v.visitLocation', response.visitLocation);
              	component.set('v.codVisit', response.codVisit);
                component.set('v.visitFeedback', response.visitFeedback);

        	}
        }
    }
})