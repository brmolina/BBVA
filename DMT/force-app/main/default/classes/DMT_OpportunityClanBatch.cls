public with sharing class DMT_OpportunityClanBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Obtenemos de forma segura el RecordTypeId
        Id dmtRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('DMT_Opportunity')
            .getRecordTypeId();

        // SOQL con los filtros requeridos:
        // 1. RecordType = 'DMT_Opportunity'
        // 2. DMT_Product_Area__c = 'IB&F'
        // 3. DMT_Clan_Call_Code__c no es '200', 'OK' ni 'ERROR'
        // 4. DMT_Clan_Retry_Number__c < 3 (o es nulo)
        String query = 'SELECT Id, StageName, DMT_Clan_Retry_Number__c ' +
                       'FROM Opportunity ' +
                       'WHERE RecordTypeId = :dmtRecordTypeId ' +
                       'AND DMT_Product_Area__c = \'IB&F\' ' +
                       'AND (DMT_Clan_Call_Code__c NOT IN (\'200\', \'OK\', \'ERROR\')) ' +
                       'AND (DMT_Clan_Retry_Number__c = null OR DMT_Clan_Retry_Number__c < 3)';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        for (Opportunity opp : scope) {
            System.debug('DMT_OpportunityClanBatch processing opp: ' + opp.Id);

            // Incrementamos en 1 el contador de reintentos (tratando el nulo como 0)
            Decimal currentRetries = (opp.DMT_Clan_Retry_Number__c != null) ? opp.DMT_Clan_Retry_Number__c : 0;
            
            oppsToUpdate.add(new Opportunity(
                Id = opp.Id,
                DMT_Clan_Retry_Number__c = currentRetries + 1
            ));

            // Encolamos el payload para cada oportunidad del lote
            DMT_AsyncOrchestrator.enqueue(
                new DMT_DynamicMapperPayload(
                    opp.Id,
                    'DMT_Opportunity_RTC_To_Clan',
                    opp.StageName
                )
            );
        }

        // 1. Actualizamos el número de reintentos en la BD antes del envío
        if (!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
        }

        // 2. Ejecutamos el flush para procesar los reintentos del lote
        DMT_AsyncOrchestrator.flush();
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('DMT_OpportunityClanBatch finalizado con éxito.');
    }
}