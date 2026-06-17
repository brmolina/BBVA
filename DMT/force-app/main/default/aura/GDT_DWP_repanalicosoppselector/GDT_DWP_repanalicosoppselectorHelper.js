({
    navigate : function(component, event, helper) {
          var recordid = component.get("v.recordId");//NOSONAR
        var action = component.get("c.getAccountsName");
         action.setParams({
            "recordId": component.get("v.recordId")//NOSONAR
        });
       action.setCallback(this, function(response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                console.log('entra al primer if');
                var records = response.getReturnValue();
                component.set("v.allItems", records);
                console.log(records);
                        var urlEvent = $A.get("e.force:navigateToURL");
                        urlEvent.setParams({
                            "url": 'https://isaas-aws.live.es.platform.bbva.com/?url=https%3A%2F%2Fdaeslv-kdit-mstr.biaas.live.eu.cld.nextgen.igrupobbva%2FMicroStrategy%2Fservlet%2FmstrWeb%3FServer%3DAWSLVES03.CLOUD.LOCAL%26Project%3DData%2BScience%2BLab%2BBanking%26Port%3D0%3Fevt%3D2048001%26src%3DmstrWeb.2048001%26visMode%3D0%26currentViewMedia%3D2%26documentID%3D44A650C711EA74B689D50080EFA58D20%26evt%3D2048084%26src%3DmstrWeb.oivm.rwb.2048084%26ctlKey%3DW1712CB89B8304447B056978FC5CDD4B3%26elemList%3Dh'//NOSONAR
                            + records + '%3BA49B31FE11EA5891F99B0080EF55C17F%26usePartDisplay%3D0%26currentIncludeState%3Dtrue%26applyNow%3D1%26evtorder%3D2048001%252c2048084%262048001%3D1%262048084%3D1%26evtwait%3Dtrue'//NOSONAR
                        });
                        urlEvent.fire();
                    }
        });
        $A.enqueueAction(action);
    },
    navigate2 : function(component, event, helper) {
        var recordid = component.get("v.recordId");//NOSONAR
        var action = component.get("c.getAccountsName");
         action.setParams({
            "recordId": component.get("v.recordId")//NOSONAR
        });
       action.setCallback(this, function(response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                var records = response.getReturnValue();
                component.set("v.allItems", records);
                        var urlEvent = $A.get("e.force:navigateToURL");
                        urlEvent.setParams({
                            "url": 'https://isaas-aws.live.es.platform.bbva.com/?url=https%3A%2F%2Fdaeslv-kdit-mstr.biaas.live.eu.cld.nextgen.igrupobbva%2FMicroStrategy%2Fservlet%2FmstrWeb%3FServer%3DAWSLVES03.CLOUD.LOCAL%26Project%3DData%2BScience%2BLab%2BBanking%26Port%3D0%3Fevt%3D2048001%26src%3DmstrWeb.2048001%26visMode%3D0%26currentViewMedia%3D2%26documentID%3D251FCEF911EAB07A74080080EF65ECAB%26evt%3D2048084%26src%3DmstrWeb.oivm.rwb.2048084%26ctlKey%3DW0999F81CB5A8422A8AB789AEC92E2AD7%26elemList%3Dh'//NOSONAR
                            + records + '%3B2DC45CA711EAB49CAE160080EF258FD8%26usePartDisplay%3D0%26currentIncludeState%3Dtrue%26applyNow%3D1%26evtorder%3D2048001%252c2048084%262048001%3D1%262048084%3D1%26evtwait%3Dtrue'//NOSONAR
                        });
                        urlEvent.fire();
                    }
        });
        $A.enqueueAction(action);
    },
	 accountname : function (component, event, helper) {
        var recordid = component.get("v.recordId");//NOSONAR
        var action = component.get("c.getproduct");
        action.setParams({
            "recordId": component.get("v.recordId")//NOSONAR
        });
        action.setCallback(this, function(response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                var product = response.getReturnValue();
        if(product.includes('Cash Management')){
          component.set('v.condition1',true);
        }else{
          component.set('v.condition1',false);
        }
                if(product.includes('Working Capital')){
          component.set('v.condition2',true);
        }else{
          component.set('v.condition2',false);
        }
            }
        });
        $A.enqueueAction(action);
    }
})