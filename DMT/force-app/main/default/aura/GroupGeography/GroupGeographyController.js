({
    doInit: function (cmp, event, helper) {
        helper.onInit(cmp, event, helper);
    },
    navigateToMyComponent : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:GroupGeographyDetail",
            componentAttributes: {
                recordId : component.get("v.recordId")
            }
        });
        evt.fire();
    },
    navigateToTB : function(component, event, helper) {
    	console.log('::::navigateToTB: init ');
    	var component_target = event.currentTarget;
    	var userTBId = component_target.dataset.userTB;
        console.log('::::userTBid: ' + userTBId);
    },
    handleCountryPicked: function(cmp, event, helper) {
    	console.log("::::::handleCountryPicked() hijo controller");
        var mapValores = cmp.get("v.mapCountriesInfo");
        console.log("::::::mapValores cmp: " + mapValores);
        var mapCountriesInfoString = cmp.get("v.mapCountriesInfoString");
        console.log("::::::mapCountriesInfoString cmp: " + mapCountriesInfoString);
        var lstCountries = cmp.get("v.lstCountries");
        console.log("::::::lstCountries cmp: " + lstCountries);
        var mapMarkers = cmp.get("v.mapMarkers");
        console.log("::::::mapMarkers cmp: " + mapMarkers);
    	helper.getCountryPicked(cmp, event, helper);
  	}
});