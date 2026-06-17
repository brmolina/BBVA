({
	fetchPickListValProdFam: function(component, fieldName, elementId) {
        var action = component.get("c.getselectOptions");
        action.setParams({
            "objObject": component.get("v.objInfo"),
            "fld": fieldName,
            "lookupObject": ""

        });
        var opts = [];
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var allValues = Object.values(response.getReturnValue());
                for (var i = 0; i < allValues.length; i++) {
                    opts.push({
                        class: "optionClass",
                        label: allValues[i],
                        value: allValues[i]
                    });
                }
                component.set("v.optionsPF", opts);
            }
        });
        $A.enqueueAction(action);
    },
    fetchPickListValRole: function(component, fieldName, elementId) {
        var lookupObject = component.get("v.lookupObject");
        var action = component.get("c.getselectOptions");
        action.setParams({
            "objObject": component.get("v.objInfoBBVAMT"),
            "fld": fieldName,
            "lookupObject": lookupObject
        });
        var opts = [];
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var allValues = Object.values(response.getReturnValue());
                for (var i = 0; i < allValues.length; i++) {
                    if(((allValues[i] != $A.get("$Label.c.DES_ROLE_GLOBAL_BANKER") && allValues[i] != $A.get("$Label.c.DES_ROLE_SECONDARY_GB") && allValues[i] != $A.get("$Label.c.DES_ROLE_INDUSTRY_HEAD"))
                    || (!component.get("v.existsGB") && allValues[i] == $A.get("$Label.c.DES_ROLE_GLOBAL_BANKER"))
                    || (!component.get("v.existsSGB") && allValues[i] == $A.get("$Label.c.DES_ROLE_SECONDARY_GB"))
                    || (!component.get("v.existsIH") && allValues[i] == $A.get("$Label.c.DES_ROLE_INDUSTRY_HEAD")))
                    &&  allValues[i] != $A.get("$Label.c.DES_Product_Specialist")
                       &&  allValues[i] != $A.get("$Label.c.DES_ROLE_GCC_POOL")
                      ){
                        if(allValues[i] == $A.get("$Label.c.DES_Role_Transactional_Banker")){
                            opts.push({
                                class: "optionClass",
                                label: 'Transaction Banker',
                                value: allValues[i]
                            });
                        }else{
                          	opts.push({
                                class: "optionClass",
                                label: allValues[i],
                                value: allValues[i]
                            });
                        }

                    }

                }
                component.set("v.optionsRole", opts);
            }
        });
        $A.enqueueAction(action);
    },
    fetchPickListValScope: function(component, fieldName, elementId, role) {
        var action = component.get("c.getselectOptions");
        action.setParams({
            "objObject": component.get("v.objInfoBBVAMT"),
            "fld": fieldName,
            "lookupObject": ""
        });
        var optsNoGlobal = [];
        var opts = [];
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var allValues = Object.values(response.getReturnValue());
                var allLabel = Object.keys(response.getReturnValue());
                for (var i = 0; i < allValues.length; i++) {
                    if(role != $A.get("$Label.c.DES_ROLE_GLOBAL_BANKER") && role != $A.get("$Label.c.DES_ROLE_SECONDARY_GB") && role != $A.get("$Label.c.DES_ROLE_INDUSTRY_HEAD") && role != $A.get("$Label.c.DES_ROLE_CIB_BANKER") && allValues[i] != $A.get("$Label.c.DES_SCOPE_GLOBAL")){
                       opts.push({
                            class: "optionClass",
                            label: allLabel[i],
                            value: allValues[i]
                        });

                    }else if((role == $A.get("$Label.c.DES_ROLE_GLOBAL_BANKER") || role == $A.get("$Label.c.DES_ROLE_SECONDARY_GB") ||  role == $A.get("$Label.c.DES_ROLE_INDUSTRY_HEAD") || role == $A.get("$Label.c.DES_ROLE_CIB_BANKER")) && allValues[i] == $A.get("$Label.c.DES_SCOPE_GLOBAL")){
                        opts.push({
                            class: "optionClass",
                            label: allLabel[i],
                            value: allValues[i]
                        });
                        component.set("v.scopeSelected", allValues[i]);
                        component.set("v.memberScope", allValues[i]);
                    }

                }
                if(opts.length > 0){
                    component.set("v.optionsScope", opts);
                }
            }
        });
        $A.enqueueAction(action);
    },
    fetchPickListValCoverage: function(component, fieldName, elementId, role) {
        var action = component.get("c.getselectOptions");
        action.setParams({
            "objObject": component.get("v.objInfo"),
            "fld": fieldName,
            "lookupObject": ""
        });
        var optsNoGlobal = [];
        var opts = [];
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var allValues = Object.values(response.getReturnValue());
                var allLabel = Object.keys(response.getReturnValue());
                for (var i = 0; i < allValues.length; i++) {

                    opts.push({
                        class: "optionClass",
                        label: allLabel[i],
                        value: allValues[i]
                    });

                }
                if(opts.length > 0){
                    component.set("v.optionsCoverage", opts);
                }

            }
        });
        $A.enqueueAction(action);
    }
})