({
	onInit: function (component, event, helper) {
        var action = component.get("c.getAccount");
    	action.setParams({
			"clientId": component.get("v.recordId")
		});
        action.setCallback(this, function(response) {
            console.log('response' + response);
            var state = response.getState();
            console.log(state);
            if (state === "SUCCESS") {
                var obj = response.getReturnValue() ;
                console.log(obj);
                component.set('v.center', {
                    location: {
                        City: 'Madrid'
                    }
                });

                var list = document.getElementsByTagName("map");
                console.log(':::lista mapas: ' + JSON.stringify(list));


				component.set('v.mapMarkers',obj);

                //parametrizado:
                component.set('v.zoomLevel', 1);
                component.set('v.markersTitle', 'Localizaciones');
                component.set('v.showFooter', false);
            }

        });
        $A.enqueueAction(action);
    },
    navigateGoBackAccount : function(cmp, event, helper) {
        cmp.find("nav").navigate({
            type: "standard__recordPage",
            attributes: {
                recordId: cmp.get("v.recordId"),
                objectApiName: "PersonAccount",
                actionName: "view"
            }
        });
    }
})