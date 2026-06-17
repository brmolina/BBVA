({
    afterScriptsLoaded : function(component, event, helper) {

        component.set('v.ready', true);
        component.set('v.country', '');
        helper.createChart(component);
        console.log('detailForm: ' + component.get('v.detailForm'));
        console.log('lstCountries en el controller: ' + component.get('v.lstCountries'));
    },

    doInit : function(component, event, helper) {
        helper.getCountries(component, event, helper);
    },

    navigateToMyComponent : function(component, event, helper) {
		var country = component.get('v.country');
        console.log('country navigate' + country);
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:DES_APRevenuesEvolution",
            componentAttributes: {
                recordId : component.get("v.recordId"),
                detailForm : 'true',
                tableSize : null,
                country : component.get('v.country')
            }
        });
        evt.fire();
    },

    clickCountry : function(component, event, helper) {
        var country = event.getSource().get("v.name");
        console.log('country: ' + country);
        component.set('v.country', country);

        helper.createChart(component, event, helper);

    },

})