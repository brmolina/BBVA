/*
* Schedulable for DES_Batch_BBVAManualSharing batch
*/
global without sharing class DES_Schedulable_BBVASharing implements Schedulable {
    /*
    * Method for schedule
    */
    global void execute(SchedulableContext scMain) {
        Id batchInstanceId = Database.executeBatch(new DES_Batch_BBVAManualSharing(), 1);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
    }
}