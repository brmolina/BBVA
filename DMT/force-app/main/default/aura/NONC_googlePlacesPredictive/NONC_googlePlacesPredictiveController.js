({
  getCities: function(component, event, helper) {
    var params = {
      'input': component.get('v.location')
    };

    helper.callServer(component, 'c.getSuggestions', function(response) {
      var resp = JSON.parse(response);
      component.set('v.predictions', resp.predictions);
    }, params);
  },
  getCityDetails: function(component, event, helper) {

    var selectedItem = event.currentTarget;
    var placeid = selectedItem.dataset.placeid;

    var params = {
      'placeId': placeid
    };

    helper.callServer(component, 'c.getPlaceDetails', function(response) {
      let placeDetails = JSON.parse(response);

      component.set('v.location', placeDetails.result.formatted_address);
      component.set('v.latitude', placeDetails.result.geometry.location.lat);
      component.set('v.longitude', placeDetails.result.geometry.location.lng);
      component.set('v.predictions', []);

      let adrAddress = placeDetails.result.adr_address;

      // eslint-disable-next-line
      let parser = new DOMParser();
      let xmlDoc = parser.parseFromString(adrAddress, 'text/html');

      let searchedStreet = (xmlDoc.getElementsByClassName('street-address').length === 0) ? '' : xmlDoc.getElementsByClassName('street-address')[0].innerText;
      let searchedCity = (xmlDoc.getElementsByClassName('locality').length === 0) ? '' : xmlDoc.getElementsByClassName('locality')[0].innerText;
      let searchedState = (xmlDoc.getElementsByClassName('region').length === 0) ? '' : xmlDoc.getElementsByClassName('region')[0].innerText;
      let searchedCountry = (xmlDoc.getElementsByClassName('country-name').length === 0) ? '' : xmlDoc.getElementsByClassName('country-name')[0].innerText;
      let searchedPostalCode = (xmlDoc.getElementsByClassName('postal-code').length === 0) ? '' : xmlDoc.getElementsByClassName('postal-code')[0].innerText;

      let makersObject = [
        {
          location: {
            Latitude: placeDetails.result.geometry.location.lat,
            Longitude: placeDetails.result.geometry.location.lng
          },
          title: placeDetails.result.name
        }
      ];

      component.set('v.mapMarkers', makersObject);
      component.set('v.zoomLevel', 16);

      makersObject[0].location.Street = searchedStreet;
      makersObject[0].location.City = searchedCity;
      makersObject[0].location.State = searchedState;
      if (searchedCountry !== '') {
        makersObject[0].location.Country = searchedCountry;
      }
      if (searchedPostalCode !== '') {
        makersObject[0].location.PostalCode = searchedPostalCode;
      }
      helper.fireComponentEvent(component, event, helper, makersObject);
    }, params);
  }
});