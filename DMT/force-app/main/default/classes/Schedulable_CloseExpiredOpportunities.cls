/**
*FECHA          -   AUTOR           -   DESCRIPCIÓN DEL CAMBIO
*15/09/2019     -   Accenture JSS   -   Creación: Clase programable que lanza el Batch de cierre de oportunidades expiradas
*/ 
global without sharing class Schedulable_CloseExpiredOpportunities implements Schedulable {
    global void execute(SchedulableContext scMain) {
        final Batches_Process_Parameters__mdt batchParams = [SELECT DeveloperName, MasterLabel, Batch_Param__c, Batch_Size__c 
                                                             FROM Batches_Process_Parameters__mdt 
                                                             WHERE DeveloperName = 'Close_Expired_Opportunities' LIMIT 1];

        final Integer batchParam = (Test.isRunningTest() ? 1 : Integer.valueOf(batchParams.Batch_Param__c));
        final Integer batchSize = (Test.isRunningTest() ? 200 : batchParams.Batch_Size__c.intValue());
        Id batchInstanceId = Database.executeBatch (new Batch_CloseExpiredOpportunities(batchParam),batchSize);
        System.debug('>>>>>>> Schedulable_CloseExpiredOpportunities batchInstanceId: ' + batchInstanceId);
    }
}