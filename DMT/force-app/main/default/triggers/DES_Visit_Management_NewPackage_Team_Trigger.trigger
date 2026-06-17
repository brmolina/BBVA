/**************************************************************************************************************
Name:            DES_Visit_Management_NewPackage_Team_Trigger
Description:     Trigger class for dwp_kitv__Visit_Management_Team__c object
Test Class:

Version        Date            Author            Summary of changes
--------------------------------------------------------------------------------------------------------------
0.1            11/05/2018      Accenture          Class creation
**************************************************************************************************************/
trigger DES_Visit_Management_NewPackage_Team_Trigger on dwp_kitv__Visit_Management_Team__c(before insert, before delete, after delete, after insert, after update) {
    dwp_kitv.Visit_Management_Team_Handler handler = new dwp_kitv.Visit_Management_Team_Handler();
    DES_VisitManagementTeam_TriggerHandler DES_handler = new DES_VisitManagementTeam_TriggerHandler();
    if(trigger.isBefore) {
        if(trigger.isInsert) {
            handler.VisitManagementTeamBeforeInsert(trigger.new);
            DES_VisitManagementTeam_TriggerHandler.fillRoleVisitManagementTeam(trigger.new);
            DES_VisitManagementTeam_TriggerHandler.fillVisitManualSharing(trigger.new);
        }/* else if(trigger.isDelete) {
            DES_handler.logicBeforeDelete(trigger.oldMap);
        }*/
    }

    if(trigger.isAfter) {
        if(trigger.isInsert) {
            //DES_VisitManagementTeam_TriggerHandler.updateFamiliesOnVisit(trigger.new, false);
            dwp_kitv.Visit_Management_Team_Confidential.updateFamiliesOnVisit(trigger.new, false);
            DES_VisitManagementTeam_TriggerHandler.fillInvolvedProducts(trigger.new, false);
            // DES_HandlerTerritory.shareVisitFromVisitMember(trigger.new,trigger.old);
            Visit_Management_Team_TriggerHandler.onAfterInsert(Trigger.new);
            DES_VisitManagementTeam_TriggerHandler.updateParticipantFields(Trigger.new);
        }
        if(trigger.isDelete) {
            DES_VisitManagementTeam_TriggerHandler.deleteManualSharing(Trigger.new, Trigger.oldMap);
            //DES_VisitManagementTeam_TriggerHandler.updateFamiliesOnVisit(trigger.old, true);
            dwp_kitv.Visit_Management_Team_Confidential.updateFamiliesOnVisit(trigger.old, true);
            DES_VisitManagementTeam_TriggerHandler.recalculateInvolvedProducts(trigger.old);
            // DES_HandlerTerritory.shareVisitFromVisitMember(null,trigger.old);
            Visit_Management_Team_TriggerHandler.onAfterDelete(Trigger.old);
        }
    }
}