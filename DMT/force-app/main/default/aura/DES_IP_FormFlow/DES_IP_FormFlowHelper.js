({
  executeAction : function(component, action, callback) {
    // Promise Execute action against the server
    return new Promise(function(resolve, reject) {
      action.setCallback(this,
          function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
              resolve(response.getReturnValue());
            } else if (state === 'ERROR') {
              var errors = response.getError();
              if (errors) {
                if (errors[0] && errors[0].message) {
                  reject(Error('Error message: '
                      + errors[0].message));
                }
              } else {
                reject(Error('Unknown error'));
              }
            }
          });
      $A.enqueueAction(action);
    });
  },
  fillComponent : function(component, http, operation) {
    if (operation === 'consulta') {
      if (http.responseText != null) {
        var response = JSON.parse(http.responseText);
        component.set('v.owner', response.managerName);
        component.set('v.name', response.operationName);
        component.set('v.q1',
            response.listedComments);
        component.set('v.q2', response.notPublicComments);
        component.set('v.needDescription', response.operationDescription);
      }
    }

  },
  selectOperation : function(component, operation, url, http) {
    var codOppOwner = component.get('v.owner');
    var codOpportunity = component.get('v.codOpportunity');
   var externalId = component.get('v.codForm');

    if (operation === 'alta') {
      var name = component.get('v.name');
      var needDescription = component.get('v.needDescription');

      const optyData = {
        managerName : codOppOwner,
        operationName : name,
        operationDescription : needDescription,
         compilanceFormCode : externalId
      };

      url = url + $A.get("$Label.c.DES_IP_URL_OPP") + codOpportunity+ $A.get("$Label.c.DES_IP_URL_OPP_FORM") ;
      try {
        http.open("POST", url, true);
        http.withCredentials = true;
      }catch(error) {
      }
      http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"),
          codOppOwner);
      http.setRequestHeader("Content-Type", "application/json");
      http.send(JSON.stringify(optyData));

    } else if (operation === 'consulta') {

      url = url + $A.get("$Label.c.DES_IP_URL_OPP") + codOpportunity+ $A.get("$Label.c.DES_IP_URL_OPP_FORM") + externalId;
      http.open("GET", url, true);
      http.withCredentials = true;
      http.setRequestHeader("Content-Type", "application/json");
      http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"),
          codOppOwner);
      http.send(null);

    } else if (operation === 'borrado') {

      url = url + $A.get("$Label.c.DES_IP_URL_OPP") + codOpportunity+ $A.get("$Label.c.DES_IP_URL_OPP_FORM") + externalId  + "?_method=DELETE";

      http.open("POST", url, true);
      http.withCredentials = true;
      http.setRequestHeader("Content-Type", "application/json");
      http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"),
          codOppOwner);
      http.send(null);
    }

  }
})