trigger OpportunityTeamMemberTrigger on OpportunityTeamMember (after insert, before delete, after delete) {
    if (trigger.isBefore && Trigger.isDelete){
            DES_HandlerTerritory.shareOTM( null,trigger.oldMap);
	}
    if(trigger.isAfter){
        if(trigger.isInsert) {
             DES_HandlerTerritory.shareOTM(trigger.newMap, trigger.newMap);
        }
        if (trigger.isDelete) {
             DES_HandlerTerritory.shareOTM(trigger.oldMap, trigger.oldMap);
        }
    }
}