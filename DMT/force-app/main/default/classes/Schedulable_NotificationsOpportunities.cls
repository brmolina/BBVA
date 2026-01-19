/**
*FECHA          -   AUTOR           -   DESCRIPCIÓN DEL CAMBIO
*15/09/2019     -   Accenture JSS   -   Creación: Clase programable que lanza el Batch de notifiaciones de oportunidades vencidas
*/ 
global without sharing class Schedulable_NotificationsOpportunities implements Schedulable{
    global void execute(SchedulableContext scMain){
		final Batches_Process_Parameters__mdt batchParams = [SELECT DeveloperName, MasterLabel, Batch_Param__c, Batch_Size__c 
                                                             FROM Batches_Process_Parameters__mdt 
                                                             WHERE DeveloperName = 'Notifications_Opportunities' LIMIT 1];

        final Integer batchParam_N1 = (Test.isRunningTest() ? 3 : Integer.valueOf(batchParams.Batch_Param__c.split(';')[0]));
        final Integer batchParam_N2 = (Test.isRunningTest() ? 10 : Integer.valueOf(batchParams.Batch_Param__c.split(';')[1]));
        final Integer batchSize = (Test.isRunningTest() ? 200 : batchParams.Batch_Size__c.intValue());
        
        Id batchInstanceId = Database.executeBatch (new Batch_NotificationsOpportunities(batchParam_N1,batchParam_N2),batchSize);
    }
}