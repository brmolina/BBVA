/*
  * @author Global Desktop
  * @description RecalculateAccountFieldsSchedulable
  *FECHA          -   AUTOR           -   DESCRIPCIÓN DEL CAMBIO
  *01/10/2019     -   JSS             -   Se modifica para que coja dinámicamente de custom meta data el tamaño del batchsize
  */
global with sharing class RecalculateAccountFieldsSchedulable implements Schedulable {
    /*
    * @author Global Desktop
    * @description execute
    */
    global void execute(SchedulableContext scMain) {
       final Batches_Process_Parameters__mdt batchParams = [SELECT DeveloperName, MasterLabel, Batch_Param__c, Batch_Size__c 
                                                             FROM Batches_Process_Parameters__mdt 
                                                             WHERE DeveloperName = 'Recalculate_Account_Fields' LIMIT 1];

        final Integer batchSize = (Test.isRunningTest() ? 200 : batchParams.Batch_Size__c.intValue());        
        Id batchInstanceId = Database.executeBatch(new RecalculateAccountFieldsBatch(), batchSize);
        System.debug('>>>>>>> batchInstanceId: ' + batchInstanceId);
    }

}