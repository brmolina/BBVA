/**
*FECHA          -   AUTOR                   -   DESCRIPCIÓN DEL CAMBIO
*25/11/2019     -   Global Desktop JSS      -   Creación: Clase programable que lanza el Batch de Account Planning para actualizar pipelines y revenues
*/ 
global without sharing class Schedulable_AP_UpdatePipelineAndRevenues implements Schedulable{
    global void execute(SchedulableContext scMain) {
		final Batches_Process_Parameters__mdt batchParams = [SELECT DeveloperName, MasterLabel, Batch_Param__c, Batch_Size__c 
                                                             FROM Batches_Process_Parameters__mdt 
                                                             WHERE DeveloperName = 'AP_UpdatePipelineAndRevenues' LIMIT 1];

        final Integer batchSize = (Test.isRunningTest() ? 200 : batchParams.Batch_Size__c.intValue());
        Id batchInstanceId = Database.executeBatch (new Batch_AP_UpdatePipelineAndRevenues(batchParams.Batch_Param__c),batchSize);
    }
}