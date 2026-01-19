/**
* ────────────────────────────────────────────────────────────────────
* Profitability Sheet Participant Trigger Handler
*
* ────────────────────────────────────────────────────────────────────
* @author      Torcuato tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2021-08-06
* @modified
* @systemLayer BusinessLogic
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
public with sharing class ProfSheetParticipantTriggerHandler {

    private static ProfSheetParticipantTriggerHandler instance;

    public static ProfSheetParticipantTriggerHandler getInstance() {
        if (instance == null) {
            instance = new ProfSheetParticipantTriggerHandler();
        }
        return instance;
    }

    public void afterUpsert(List<cuco__profitability_sheet_participant__c> triggerNew) {

        Set<Id> accountIds = new Set<Id>();
        Set<Id> profSheetIds = new Set<Id>();
        Map<Id, Id> parents = new Map<Id, Id>();
        Map<Id, cuco__profitability_sheet__c> profSheetsMap = new Map<Id, cuco__profitability_sheet__c>();
        Set<Id> profSheets2Update = new Set<Id>();

        for (cuco__profitability_sheet_participant__c participant : triggerNew) {
            accountIds.add(participant.cuco__participant_id__c);
            profSheetIds.add(participant.cuco__gf_profitability_sheet_id__c);
        }

        List<Account> accounts = [SELECT Id, DES_Main_Parent__c, Is_Group__c FROM Account WHERE Id IN :accountIds];
        List<cuco__profitability_sheet__c> profSheets = [SELECT Id, cuco__participant_id__c FROM cuco__profitability_sheet__c WHERE Id IN: profSheetIds];

        for (Account account : accounts) {
            if (account.DES_Main_Parent__c != null && !account.Is_Group__c ) {
                parents.put(account.Id, account.DES_Main_Parent__c);
            } else {
                parents.put(account.Id, account.Id);
            }
        }

        for (cuco__profitability_sheet__c profsheet : profSheets) {
        	profSheetsMap.put(profsheet.Id, profsheet);
        }

        for (cuco__profitability_sheet_participant__c participant : triggerNew) {
           cuco__profitability_sheet__c profSheet = profSheetsMap.get(participant.cuco__gf_profitability_sheet_id__c);
           profSheet.cuco__participant_id__c = parents.get(participant.cuco__participant_id__c);
           profSheets2Update.add(participant.cuco__gf_profitability_sheet_id__c);
        }

        if (!profSheets2Update.isEmpty()) {
            List<cuco__profitability_sheet__c> lprofSheets2Update = new List<cuco__profitability_sheet__c>();
            for (Id profSheetId :profSheets2Update ) {
                lprofSheets2Update.add(profSheetsMap.get(profSheetId));
            }
            update lprofSheets2Update;
        }
    }

}