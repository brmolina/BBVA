/*
* Schedulable for Batch_MergeProspects
*/
global with sharing class ScheduleMergeProspects implements Schedulable {
  /*
  * Schedule method
  */
  global void execute(SchedulableContext scMain){
    final Id batchInstanceId = Database.executeBatch(new Batch_MergeProspects(), 1);
    system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
  }
}