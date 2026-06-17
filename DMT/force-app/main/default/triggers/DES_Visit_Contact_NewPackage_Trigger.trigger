/**************************************************************************************************************
Name:            Visit_Contact_NewPackage_Trigger
Description:     Trigger class for dwp_kitv__Visit_Contact__c object
Test Class:      

Version        Date            Author            Summary of changes
--------------------------------------------------------------------------------------------------------------
0.1            11/05/2018      Accenture          Class creation    
**************************************************************************************************************/
trigger DES_Visit_Contact_NewPackage_Trigger on dwp_kitv__Visit_Contact__c(before insert/*, before update*/) {
    dwp_kitv.Visit_Contact_Handler handler = new dwp_kitv.Visit_Contact_Handler();
    if(trigger.isBefore) {
        if(trigger.isInsert) {
            DES_ContactVisitHelper.validarContactosDuplicados(trigger.new);
            handler.visitContactBeforeInsert(trigger.new);
            DES_ContactVisitHelper.relatedContactUpdate(trigger.new, Trigger.oldMap);
            DES_ContactVisitHelper.mainContactNew(trigger.new);
        }/* else if(trigger.isUpdate) {
        	DES_ContactVisitHelper.relatedContactUpdate(trigger.new, Trigger.oldMap);
        }*/
     }
}