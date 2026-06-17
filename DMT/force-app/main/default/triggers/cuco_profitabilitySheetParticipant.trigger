/**
* @author       torcuato.tejada.contractor@bbva.com
* @date         06/08/2021
* @description  Profitability Sheet Participant Trigger
*
*/
trigger cuco_profitabilitySheetParticipant on cuco__profitability_sheet_participant__c (after insert, after update) {

    final ProfSheetParticipantTriggerHandler handler = ProfSheetParticipantTriggerHandler.getInstance();

    if(Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            handler.afterUpsert(Trigger.new);
        }
    }
}