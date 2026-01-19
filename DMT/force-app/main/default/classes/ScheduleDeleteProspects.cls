/*
* Schedulable for Batch_DeleteProspectGroup
*/
global with sharing class ScheduleDeleteProspects implements Schedulable {
  /*
  * Schedule method
  */
  global void execute(SchedulableContext scMain){
    final Id batchInstanceId = Database.executeBatch(new Batch_DeleteProspectGroup(), 2000);
    system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
  }
}