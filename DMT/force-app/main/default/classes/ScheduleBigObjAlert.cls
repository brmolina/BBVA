/*
* Schedulable for AlertBigObject
*/
public with sharing class ScheduleBigObjAlert implements Schedulable {
  /*
  * Schedule method
  */
  public void execute(SchedulableContext scMain) {
    final Id batchInstanceId = Database.executeBatch(new AlertBigObject(), 200);
    system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
  }
}