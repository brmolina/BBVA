global with sharing class DMT_SchedulableBatchCloseLostOpportunity implements Schedulable {
    global void execute(SchedulableContext sc) {
        DMT_CloseLostOpportunityBatch batch = new DMT_CloseLostOpportunityBatch();
        Database.executeBatch(batch, 200);
    }
}