trigger CampaingMember on CampaignMember (after insert, before update, after update, before delete) {
    if (Trigger.isBefore) {
        if (Trigger.isDelete || Trigger.isUpdate) {
            CampaignMemberUtils.deleteCampaignMembers(Trigger.old);
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            CampaignMemberUtils.insertCampaignMembers(Trigger.new);
        }
    }
}