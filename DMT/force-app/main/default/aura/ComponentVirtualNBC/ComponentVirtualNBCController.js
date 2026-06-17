({
    doInit : function(component, event, helper) {
        helper.virtualNBC(component);
    },
    nbcChange : function(component, event, helper) {
        helper.descNBC(component,event);
       	component.set('v.disabled', true);
    },

    handleSuccess: function(cmp, event, helper) {
        cmp.set('v.disabled', false);
    },

    handleError: function(cmp, event, helper) {
        cmp.set('v.disabled', false);
        var resp = cmp.get('v.resp');
        console.log('resp>>>>> ',resp);
        var toastEvent = $A.get("e.force:showToast");
        if(resp === "Success") {
            console.log('Entro resp = Success');
            toastEvent.setParams({
            "type": "success",
            "title": "Success!",
            "message": "NBC Opportunity Summary saved"
        });
        } else {
        toastEvent.setParams({
            "type": "error",
            "title": "Error!",
            "message": resp
        });
        }
        toastEvent.fire();
    }

})