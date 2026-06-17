({
    retrieveData: function (cmp, event, helper) {
        var accountId = cmp.get("v.recordId");
        var nestedData = cmp.get("c.getTrigDetail");
        var familyCode = cmp.get("v.familyParam");

        console.log(':::retrieveData: ' + familyCode);
        nestedData.setParams({
          "clientId" : accountId,
          "family"  : familyCode
        });

        nestedData.setCallback(this, function(response){
        if(response.getState() === "SUCCESS"){
                var resultData = JSON.parse(response.getReturnValue());
                if(resultData !== null) {
                    cmp.set('v.gridColumns', resultData.wrColumns);
                    cmp.set("v.gridData", resultData.wrData);
                    helper.expandAllRows(cmp, event);
                }
            }
        });

        $A.enqueueAction(nestedData);
    },
    expandAllRows: function(cmp, event) {
        var tree = cmp.find('potencialBBVAdata');
        tree.expandAll();
    },
    navigateGoBackAccount: function (component, event, helper) {
        component.find("nav").navigate({
            type: "standard__recordPage",
            attributes: {
                recordId: component.get("v.recordId"),
                objectApiName: "PersonAccount",
                actionName: "view"
            }
        });
    },
    navigateGoBackFamilyDummy: function (component, event, helper) {
        // New version since api 43, cambiado a nombre dummy porque da fallos por caché, vuelta a la versión del e.force:navigateTocomponent
        component.find("nav").navigate({
            type: "standard__component",
            attributes: {
                componentName: "c__ViewFamilySection"
            },
            state: {
                c__familyChecked: component.get("v.familyParam"),
                c__recordId: component.get("v.recordId")
            }

        });
    },
    navigateGoBackFamily: function (component, event, helper) {
        let evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef: "c:ViewFamilySection",
            componentAttributes: {
                familyChecked: component.get("v.familyParam"),
                recordId: component.get("v.recordId")
            }
        });
        evt.fire();
    }
})