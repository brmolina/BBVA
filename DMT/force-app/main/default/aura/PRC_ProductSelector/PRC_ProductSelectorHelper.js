({
	showToast: function (component, event, helper, msgType, msg) {
		var toastEvent = $A.get("e.force:showToast");
		toastEvent.setParams({
			// "title": "Success!",
			"type": msgType,
			"message": msg
		});
		toastEvent.fire();
	},
	submitproduct: function (component, event, helper) {
		return new Promise(function (resolve, reject) {
			var formulario = component.find('formulario');
			formulario.submit();
			resolve();
		});
	},
    getpicklist: function (component, helper) {
        var action = component.get('c.getPickList');
                     					console.log('hi<<<<<<<<<<<<<<<');

         action.setCallback(this, function (response) {
             var stateStore = response.getState();
            if (stateStore === "SUCCESS") {
                var storeRes = JSON.parse(response.getReturnValue());
                var storeStatus = storeRes.status;
                if (storeRes != null && storeStatus === 200) { //NOSONAR
                    var body = JSON.parse(storeRes.body);
                    for(var i=0;i < body.data.catalogs.length;i++) {
                      console.log(body.data.catalogs[i]);
                      if(body.data.catalogs[i].id === 'PRODUCTS') {
                        component.set('v.productsService',body.data.catalogs[i]);
                      }
                    }
                    component.set('v.picklists', body.data.catalogs);
                    component.set('v.pickloaded', true);
                } else {
                    component.set('v.pickloaded', false);
                }
            }
        });
        // enqueue the Action
        $A.enqueueAction(action);
    },
})