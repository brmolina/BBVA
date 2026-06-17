({
    initialize : function(component, event, helper) {
        component.set('v.showProds', false);
        let promise = helper.gtData(component, event, helper);
        promise.then(function() {
           helper.uncheckStageChanged(component, event, helper);
        }/*, segunda funcion si quiero algo en el reject */);
    },

    gtData : function(component, event, helper) {
        return new Promise(function(resolve, reject) {
            let action = component.get("c.gtData");
            action.setParams({oppId :component.get('v.recordId')});
            // Register the callback function
            action.setCallback(this, function(response) {
                if(component.isValid() && response.getState() === 'SUCCESS') {
                    let ret = response.getReturnValue();
                    if(ret.stage_changed_type__c) {
                        component.set('v.opp', ret);
                        component.set('v.showProds', true);
                        resolve();
                    } else {
                        //reject();
                    }
                    // Set the component attributes using values returned by the API call
                    component.set('v.oppliList', response.getReturnValue());
                } else {
                    helper.fireToast('Error','Error al cargar los productos, comprueba los campos obligatorios a rellenar.');
                    //reject();
                }

            });
            // Invoke the service
            $A.enqueueAction(action);
        });
	},

    uncheckStageChanged : function(component, event, helper) {
    	let action = component.get("c.uncheckStageChanged");
        action.setParams({oppId :component.get('v.recordId')});
        // Register the callback function
        action.setCallback(this, function(response) {
            if (component.isValid() && response.getState() === 'SUCCESS') {
                let ret = response.getReturnValue();
                if (ret !== 'OK') {
                	helper.fireToast('Error', ret);
                }
            } else {
                helper.fireToast('Error','Error al cargar los productos, comprueba los campos obligatorios a rellenar.');
                //reject();
            }

        });
        // Invoke the service
        $A.enqueueAction(action);
    },

    fireToast: function(type, message) {
        let toastError = $A.get('e.force:showToast');
        toastError.setParams({
            'title': type + '!',
            'type': type.toLowerCase(),
            'message': message
        });
        toastError.fire();
    }

})