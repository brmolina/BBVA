/**********************************************************************************
* @author       Glbal Desktop
* @date         06/09/2021
* @description  batch programado para el borrado de tier 
**********************************************************************************/
global with sharing class GTB_schedulable_allmonths implements Schedulable {//NOSONAR
  /*
  * @author Global Desktop
  **/
    global void execute(SchedulableContext scMain) {
        final List<Batches_Process_Parameters__mdt> batchParams = new List<Batches_Process_Parameters__mdt>([SELECT DeveloperName, MasterLabel, Batch_Param__c, Batch_Size__c FROM Batches_Process_Parameters__mdt WHERE DeveloperName = 'DES_BatchSize_accountTierUpdateBatch' LIMIT 1]);
     	final Integer batchSize = (Test.isRunningTest() || batchParams.isEmpty() ? 1 : batchParams.get(0).Batch_Size__c.intValue());//NOSONAR
		final Id batchInstanceId = Database.executeBatch(new AccountTierDeleteBatch(), batchSize);
		system.debug('>>>>> id BATCH JO: ' + batchInstanceId);    
    }
}