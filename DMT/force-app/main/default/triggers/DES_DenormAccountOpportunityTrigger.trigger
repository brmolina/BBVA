/**************************************************************************************************************
Name:            DES_DenormAccountOpportunityTrigger
Description:     Trigger class for dwp_acmh__Denorm_Account_Opportunity__c object
Test Class:

Version        Date            Author            Summary of changes
--------------------------------------------------------------------------------------------------------------
0.1            11/05/2018      			          Class creation
0.2            27/06/2018      Accenture          Añadida funcionalidad en "before insert" para añadir el valor de DES_Opportunity_Potential_Revenue_Rollup__c
**************************************************************************************************************/
trigger DES_DenormAccountOpportunityTrigger on dwp_acmh__Denorm_Account_Opportunity__c(before insert,before update,before delete,after insert,after update,after delete) {
    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            DES_DenormAccountOppTriggerHandler.setPotentialRevenueRollup(trigger.new);
        }
    }

    else if(Trigger.isAfter){
        if(Trigger.isDelete){
            DES_DenormAccountOppTriggerHandler.denOpportunityAfterDelete(trigger.oldMap);
            Account_Without_Sharing.updateRelatedAccount(trigger.new, trigger.oldMap, true);
        }
        else if(Trigger.isInsert){
            Account_Without_Sharing.updateRelatedAccount(trigger.new, trigger.oldMap, false);
        }
        else if(Trigger.isUpdate){
            Account_Without_Sharing.updateRelatedAccount(trigger.new, trigger.oldMap, false);
        }
    }
}