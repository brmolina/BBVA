/*
* Schedulable for VisitBigobject
*/
public with sharing class ScheduleBigObjVisit implements Schedulable {
  /*
  * Schedule method
  */
  public void execute(SchedulableContext scMain) {
    final Id batchInstanceId = Database.executeBatch(new VisitBigObject(), 200);
    system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
  }
}