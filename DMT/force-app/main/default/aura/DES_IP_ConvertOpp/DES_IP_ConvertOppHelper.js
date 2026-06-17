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
        component.set('v.owner', response.codOppOwner);
        component.set('v.status', response.status);
        component.set('v.name', response.name);
        component.set('v.codOpportunity', response.codOpportunity);
        component.set('v.additionalComments',
            response.additionalComments);
        var stringBbvaCountries = response.bbvaCountriesParticipants;
        var bbvaCountriesParticipants;

        if (stringBbvaCountries != null) {
          bbvaCountriesParticipants = stringBbvaCountries;
        }
        component.set('v.bbvaCountriesParticipants',
            bbvaCountriesParticipants);
        component.set('v.descReasonLostDeal',
            response.descReasonLostDeal);
        component.set('v.needDescription', response.needDescription);
        component.set('v.bookingGeography', response.bookingGeography);
      }
    }

  },
  selectOperation : function(component, operation, url, http) {
	var codOppOwner = component.get('v.owner');
    var codOpportunity = component.get('v.codOpportunity');
    if (operation === 'alta') {

      var codOstatusppOwner = component.get('v.status');
      var name = component.get('v.name');
      var additionalComments = component.get('v.additionalComments');
      var bbvaCountriesParticipants = component
          .get('v.bbvaCountriesParticipants');
      var stringBbvaCountries;
      if (bbvaCountriesParticipants !== undefined && bbvaCountriesParticipants.constructor === Array) {
        stringBbvaCountries = bbvaCountriesParticipants.join(';');
            } else {
                stringBbvaCountries = bbvaCountriesParticipants;
            }

      var descReasonLostDeal = component.get('v.descReasonLostDeal');
      var needDescription = component.get('v.needDescription');
      var bookingGeography = component.get('v.bookingGeography');

      const optyData = {
        codOppOwner : codOppOwner,
        name : name,
        codOpportunity : codOpportunity,
        status : codOstatusppOwner,
        additionalComments : additionalComments,
        bbvaCountriesParticipants : stringBbvaCountries,
        descReasonLostDeal : descReasonLostDeal,
        needDescription : needDescription,
        bookingGeography : bookingGeography
      };

      url = url + $A.get("$Label.c.DES_IP_URL_OPP");
      try {
        http.open("POST", url, true);
      }catch(error) {
      }
      http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"),
          codOppOwner);
      http.withCredentials = true;
      http.setRequestHeader("Content-Type", "application/json");
      http.send(JSON.stringify(optyData));

    } else if (operation === 'consulta') {

      url = url + $A.get("$Label.c.DES_IP_URL_OPP") + codOpportunity;
      http.open("GET", url, true);
      http.withCredentials = true;
      http.setRequestHeader("Content-Type", "application/json");
      http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"),
          codOppOwner);
      http.send(null);

    } else if (operation === 'borrado') {

      url = url + $A.get("$Label.c.DES_IP_URL_OPP") + codOpportunity + "?_method=DELETE";

      http.open("POST", url, true);
      http.withCredentials = true;
      http.setRequestHeader("Content-Type", "application/json");
      http.setRequestHeader($A.get("$Label.c.DES_IP_HEADER_USER"),
          codOppOwner);
      http.send(null);
    }

  }
})