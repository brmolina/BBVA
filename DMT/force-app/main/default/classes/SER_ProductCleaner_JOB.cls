/**
* Clase que implemente la interface Schedulable pqra poder programar el batch SER_ProductCleaner_BATCH
*/
global without sharing class SER_ProductCleaner_JOB implements Schedulable {
  /**
  * Method execute
  */
  global void execute(SchedulableContext scctx) {
    final SER_ProductCleaner_BATCH cleanerBatch = new SER_ProductCleaner_BATCH();
    Database.executebatch(cleanerBatch);
  }

  /**
  * Method execute
  */
  global void execute(SchedulableContext scctx, String query) {
    final SER_ProductCleaner_BATCH cleanerBatch = new SER_ProductCleaner_BATCH(query);
    Database.executebatch(cleanerBatch);
  }
}