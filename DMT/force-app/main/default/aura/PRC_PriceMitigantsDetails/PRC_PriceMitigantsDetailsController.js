({
    doInit: function (component, event, helper) {
       var pricingDetailsId = component.get('v.pricingDetailsId');
       console.log('pricingdetailsid: ' + pricingDetailsId);
       helper.callDetails(component, helper, pricingDetailsId);
    },
    removeMitigant: function(component, event, helper) {
        var listCodMitigant = event.getParam("value");
        console.log('** remov ' + listCodMitigant.split('--')[0]);
        var codMitigant = listCodMitigant.split('--')[1];
        if(listCodMitigant.split('--')[0] === 'Edit') {
          console.log('** edit ');
          var vieweditevt = component.getEvent('vieweditevt');
		  vieweditevt.setParam('idMitigant', codMitigant);
          vieweditevt.setParam('rating', listCodMitigant.split('--')[2]);
          vieweditevt.setParam('externalRating', listCodMitigant.split('--')[3]);
          vieweditevt.fire();
        } else if(listCodMitigant.split('--')[0] === 'Delete') {
        helper.deleteMitigant(component, helper, codMitigant);
    }
    }
})