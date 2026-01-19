/*
* Schedulable for OpportunityBigObject
*/
public with sharing class ScheduleBigObjOpp implements Schedulable {
  /*
  * Schedule method
  */
  public void execute(SchedulableContext scMain) {
    final Id batchInstanceId = Database.executeBatch(new OpportunityBigObject(), 200);
    system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
  }
}