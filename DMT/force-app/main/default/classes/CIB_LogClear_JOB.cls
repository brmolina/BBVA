/**
* @name           Migracion GNC Job
* @description    This class implements Schedulable interface and schedule Filters_BATCH batch.
* @author         BBVA. Service team.
* @date           Mayo 2020.
*/
public without sharing class CIB_LogClear_JOB implements Schedulable {

  /**
  * @description    Method execute. This method launches the batch.
  * @param          btchCtx: Database.BatchableContext. Batch context.
  * @return         Void.
  */
  public void execute(SchedulableContext schedl) {

      CIB_LogClear_BATCH cibLogClearBATCH;
      cibLogClearBATCH = new CIB_LogClear_BATCH();
      Database.executebatch(cibLogClearBATCH);

  }
}