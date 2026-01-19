public with sharing class DMT_DeleteConsolidateLineScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
       DMT_DeleteConsolidateLineBatch b = new DMT_DeleteConsolidateLineBatch(); 
       Database.executeBatch(b);
    }
 }