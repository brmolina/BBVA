({
    doInit : function(component, event, helper) {
        helper.checkPermisions(component);
        helper.checkAccountFields(component);
        var objectName = component.get('v.sObjectName');
        component.set('v.commOfferAtt.CurrencyIsoCode', $A.get("$Locale.currencyCode"));
        if(objectName === 'Account') {
            helper.inAccountInit(component, event, helper);
            component.set('v.modalView', 'newCoff');
        } else if (objectName === 'Opportunity') {
            helper.inOpportunityInit(component, event, helper);
        } else {
            component.set('v.modalView','standardAct');
        }
        helper.getPicklistVal(component, event, helper);
    },
    saveRelateCo : function(component, event, helper) {
        helper.relateCOtoOpp(component, event, helper);
    },
    saveCo : function(component, event, helper) {
        helper.saveCommercialOff(component, event, helper);
    },
    saveCOStandard : function(component, event, helper) {
        helper.saveCOStan(component, event, helper);
    },
    cancelCo : function(component, event, helper) {
        $A.get('e.force:closeQuickAction').fire();
    },
    cancelCoSt : function(component, event, helper) {
        window.history.go(-1);
    },
    createCoff : function(component, event, helper) {
        component.set('v.modalView', 'newCoff');
    },
    relateCoff : function(component, event, helper) {
        component.set('v.modalView', 'relateCoff');
    },
    accountChange : function(component, event, helper) {
        var fromLookUp = event.getParam("lookUpCleared");
        console.log('SE HA BORRAO EL LOOKUP -----> ' + fromLookUp);

        if(fromLookUp === 'account') {
            component.set('v.selectedAcc', '{}');
            component.set('v.selectedOpp', '{}');
            var childOpp = component.find('childOpp');
            childOpp.callOppClear();
        }
    },
    goToRfp : function(component, event, helper) {
        component.set('v.modalView','rfpFields');
        console.log('CONTINUEEEEE');
    },
    goToRfpOvrr : function(component, event, helper) {
        component.set('v.modalView','rfpFieldsOvrr');
        console.log('CONTINUEEEEE');
    },
    checkFields : function(component, event, helper) {
        helper.checkFieldsHelper(component, event, helper);
    },
    rfpChech : function(component, event, helper) {
        helper.rfpCheckHelper(component, event, helper);
    },
    checkRelate : function(component, event, helper) {
        helper.checkRltHelper(component, event, helper);
    }
})