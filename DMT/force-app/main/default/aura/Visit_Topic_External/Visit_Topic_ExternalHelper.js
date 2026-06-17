({
  selectOperation : function(component, operationtype1, url, http) {
    var codVisitTopic = component.get('v.codVisitTopic');
    var codOpportunity = component.get('v.codOpportunity');
    var visitTopicDescription = component.get('v.visitTopicDescription');
    var codVisit = component.get('v.codVisit');
    var visitOwner = component.get('v.visitOwner');
    var visitTopicData;
    if (operationtype1 === 'alta') {
      if(codOpportunity === '' || codOpportunity === undefined || codOpportunity === null) {
        visitTopicData = {
          codVisitTopic : codVisitTopic,
          visitTopicDescription : visitTopicDescription
        };
      } else {
        visitTopicData = {
          codVisitTopic : codVisitTopic,
          codOpportunity : codOpportunity,
          visitTopicDescription : visitTopicDescription
        };
      }

      url = url + $A.get("$Label.c.DES_IP_URL_VISIT") + codVisit + $A.get("$Label.c.DES_IP_URL_VISIT_TOPICS");

      http.open("POST", url, true);
      http.withCredentials = true;
      http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"),
                            visitOwner);
      http.setRequestHeader("Content-Type", "application/json");
      http.send(JSON.stringify(visitTopicData));

    } else if (operationtype1 === 'consulta') {

      url = url + $A.get("$Label.c.DES_IP_URL_VISIT") + codVisit + $A.get("$Label.c.DES_IP_URL_VISIT_TOPICS") + codVisitTopic;
      http.open("GET", url, true);
      http.withCredentials = true;
      http.setRequestHeader("Content-Type", "application/json");
      http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"),
                            visitOwner);
      http.send(null);

    } else if (operationtype1 === 'borrado') {

      url = url + $A.get("$Label.c.DES_IP_URL_VISIT") + codVisit + $A.get("$Label.c.DES_IP_URL_VISIT_TOPICS") + codVisitTopic + "?_method=DELETE";
      http.open("POST", url, true);
      http.withCredentials = true;
      http.setRequestHeader("Content-Type", "application/json");
      http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"),
                            visitOwner);
      http.send(null);
    } else if (operationtype1 === 'modificacion') {
      if(codOpportunity === '' || codOpportunity === undefined || codOpportunity === null) {
        visitTopicData = {
          codVisitTopic : codVisitTopic,
          visitTopicDescription : visitTopicDescription
        };
      } else {
        visitTopicData = {
          codVisitTopic : codVisitTopic,
          codOpportunity : codOpportunity,
          visitTopicDescription : visitTopicDescription
        };
      }

      url = url + $A.get("$Label.c.DES_IP_URL_VISIT") + codVisit + $A.get("$Label.c.DES_IP_URL_VISIT_TOPICS") + codVisitTopic + "?_method=PUT";
      http.open("POST", url, true);
      http.withCredentials = true;
      http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"),
                            visitOwner);
      http.setRequestHeader("Content-Type", "application/json");
      http.send(JSON.stringify(visitTopicData));

    }
  },
    fillComponent : function(component, http, operation) {
        if (operation === 'consulta') {
          	if (http.responseText != null) {
        		var response = JSON.parse(http.responseText);
       			component.set('v.visitTopicDescription', response.visitTopicDescription);
        	}
        }
    }
})