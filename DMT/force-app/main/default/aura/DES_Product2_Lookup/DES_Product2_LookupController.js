({
    doInit: function(component,event,helper){
        helper.fetchPickListValRole(component, 'DES_Member_Role__c', '');

	},
    handleChangeProdFam: function (cmp, event) {
        var selectedOptionValue = event.getParam("value");
        if(event.getParam("value") != null){
            cmp.set("v.productFamily", selectedOptionValue);
        }

    },
    handleChangeRole: function (cmp, event, helper) {
        var selectedOptionValue = event.getParam("value");
        if(event.getParam("value") != null){
            cmp.set("v.memberRole", selectedOptionValue);
            //RECALCULO LAS PICKLIST DEPENDIENTES
            helper.fetchPickListValScope(cmp, 'DES_Local_Banker_Country__c', '', event.getParam("value"));
            if(event.getParam("value") == 'Product Specialist'){
                helper.fetchPickListValProdFam(cmp, 'Family', '');
            }
            if(event.getParam("value") == $A.get("$Label.c.DES_Role_Transactional_Banker")){
                helper.fetchPickListValCoverage(cmp, 'DES_Tipo_de_Cobertura__c', '', event.getParam("value"));
            }

        }



    },
    handleChangeScope: function (cmp, event) {
        var selectedOptionValue = event.getParam("value");
        if(event.getParam("value") != null){
            cmp.set("v.memberScope", selectedOptionValue);
        }

    },
    handleChangeCoverage: function (cmp, event) {
        var selectedOptionValue = event.getParam("value");
        if(event.getParam("value") != null){
            cmp.set("v.memberCoverage", selectedOptionValue);
        }

    }
})