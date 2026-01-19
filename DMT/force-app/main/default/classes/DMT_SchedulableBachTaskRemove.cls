global with sharing class DMT_SchedulableBachTaskRemove implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new DMT_TaskApproverRelationshipRemove(), 200);
        Database.executeBatch(new DMT_TaskRelationshipRemove(), 200);
        Database.executeBatch(new DMT_TaxonomyRelationshipRemove(), 200);
    }
 }