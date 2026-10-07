@IsTest
private class DMT_OpportunityClanBatchTest {
    @TestSetup
    static void setupData() {
        TriggerBypass.bypassTrigger = true;
        try {
            Opportunity firstOpportunity = DMT_Test_DataFactory.generateOpportunity();
            Opportunity secondOpportunity = new Opportunity(
                AccountId = firstOpportunity.AccountId,
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
                    .get('DMT_Opportunity')
                    .getRecordTypeId(),
                Name = 'Clan Eligible Retry Two',
                StageName = 'Draft Opp',
                CloseDate = Date.today(),
                DMT_Opp_Id__c = 'CLAN-TEST-00002',
                DMT_CUR_Notional_Amount__c = 100,
                DMT_CurrencyText__c = 'EUR',
                DMT_DATE_Initial_Date__c = Date.today(),
                DMT_DATE_Maturity_Date__c = Date.today().addDays(1),
                Entific__c = 'ES',
                DMT_Entity__c = 'ES0182',
                DMT_Product_Area__c = 'IB&F',
                DMT_Threshold_Type__c = 'Global',
                DMT_Clan_Call_Code__c = '503',
                DMT_Clan_Retry_Number__c = 2
            );
            insert secondOpportunity;

            update new Opportunity(
                Id = firstOpportunity.Id,
                Name = 'Clan Eligible Null Retry',
                DMT_Product_Area__c = 'IB&F',
                DMT_Clan_Call_Code__c = '500',
                DMT_Clan_Retry_Number__c = null
            );
        } finally {
            TriggerBypass.bypassTrigger = false;
        }
    }

    @IsTest
    static void startReturnsAQueryLocator() {
            Test.startTest();
            Database.QueryLocator queryLocator = new DMT_OpportunityClanBatch().start(null);
            Test.stopTest();

            Assert.isNotNull(queryLocator, 'The batch start method must return a QueryLocator.');
        
    }

    @IsTest
    static void executeIncrementsRetriesForBulkScope() {
            List<Opportunity> scope = [
                SELECT Id, StageName, DMT_Clan_Retry_Number__c
                FROM Opportunity
                WHERE Name IN ('Clan Eligible Null Retry', 'Clan Eligible Retry Two')
                
            ];
            Assert.areEqual(2, scope.size(), 'The setup must provide a multi-record batch scope.');

            DMT_AsyncOrchestrator.payloadBuffer.clear();
            TriggerBypass.bypassTrigger = true;
            try {
                Test.startTest();
                new DMT_OpportunityClanBatch().execute(null, scope);
                Test.stopTest();
            } finally {
                TriggerBypass.bypassTrigger = false;
                DMT_AsyncOrchestrator.payloadBuffer.clear();
            }

            Map<String, Opportunity> opportunitiesByName = new Map<String, Opportunity>();
            for (Opportunity opportunityRecord : [
                SELECT Name, DMT_Clan_Retry_Number__c
                FROM Opportunity
                WHERE Name IN ('Clan Eligible Null Retry', 'Clan Eligible Retry Two')
            ]) {
                opportunitiesByName.put(opportunityRecord.Name, opportunityRecord);
            }

            Assert.areEqual(1, opportunitiesByName.get('Clan Eligible Null Retry').DMT_Clan_Retry_Number__c, 'A null retry count must increment from zero to one.');
            Assert.areEqual(3, opportunitiesByName.get('Clan Eligible Retry Two').DMT_Clan_Retry_Number__c, 'An existing retry count must increment by one.');
        
    }

    @IsTest
    static void executeHandlesEmptyScopeWithoutAsyncWork() {
            DMT_AsyncOrchestrator.payloadBuffer.clear();
            Integer queueableJobsBefore;
            Integer queueableJobsAfter;

            Test.startTest();
            queueableJobsBefore = Limits.getQueueableJobs();
            new DMT_OpportunityClanBatch().execute(null, new List<Opportunity>());
            queueableJobsAfter = Limits.getQueueableJobs();
            Test.stopTest();

            Assert.areEqual(queueableJobsBefore, queueableJobsAfter, 'An empty scope must not enqueue asynchronous work.');
            Assert.isTrue(DMT_AsyncOrchestrator.payloadBuffer.isEmpty(), 'An empty scope must leave the orchestrator buffer empty.');
        
    }

    @IsTest
    static void finishCompletesWithoutSideEffects() {
            Test.startTest();
            new DMT_OpportunityClanBatch().finish(null);
            Test.stopTest();

            Assert.areEqual(2, [SELECT COUNT() FROM Opportunity], 'The finish method must not modify source Opportunities.');
        
    }

    

    
}