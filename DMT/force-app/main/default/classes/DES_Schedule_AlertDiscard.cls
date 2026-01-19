/*
* Schedulable for discard alerts
*/
public without sharing class DES_Schedule_AlertDiscard implements Schedulable {
  /*
  * Method schedulable
  */
  public void execute(SchedulableContext scMain) {
    final Id batchInstanceId = Database.executeBatch(new almd.Commercial_Alert_Discard_Batch(), 1000);
    system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
  }
}