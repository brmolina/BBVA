trigger BBVAPitchTeam on pith__BBVA_Pitch_Team__c(after insert, after delete) {
    
    pith.BBVAPitchTeamHandler pitchTeamhandler = new pith.BBVAPitchTeamHandler();
    
    if(trigger.isAfter) {
        if(trigger.isInsert) {
        pitchTeamhandler.completePublicGroup(trigger.new);
        }
        if(trigger.isDelete) {
        pitchTeamhandler.getGroupMember(trigger.old);
        }
    }
    
}