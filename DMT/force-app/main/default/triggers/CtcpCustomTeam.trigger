trigger CtcpCustomTeam on ctcp__Custom_Team__c (before insert, after insert, after delete) {
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            ctcp.DES_CustomTeam_TriggerHelper.afterinsert(trigger.new);
            // CustomTeamHandler.infAlertMembersCode(trigger.new);
        } else if(Trigger.isDelete) {
            ctcp.DES_CustomTeam_TriggerHelper.afterDelete(trigger.old);
            // CustomTeamHandler.deleteMembersCode(trigger.old);
        }
    }
}