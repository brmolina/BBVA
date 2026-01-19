/**
* -----------------------------------------------------------------------------------------------
* @name        Arc_Gen_AbandonedArce_Batch_Test
* @author      nerea.ortiz.penalosa.contractor@bbva.com
* @date        2024-05-04
* @group       ARCE
* -----------------------------------------------------------------------------------------------
* @description Test class that covers: Arc_Gen_AbandonedArce_Batch
* -----------------------------------------------------------------------------------------------
* @changes
* v1.0         nerea.ortiz.penalosa.contractor@bbva.com
* |2024-05-04  Class creation
*
* v1.1         marcos.gimeno.tech@bbva.com
* |2024-06-25  Refactoring, format and business logic modifications
* -----------------------------------------------------------------------------------------------
**/
@isTest
private class Arc_Gen_AbandonedArce_Batch_Test {
    // prettier-ignore
    /** @description Cron expression to schedule the batch **/
    static String cronExpression = '0 0 12 * * ?';

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Setup method to create the test data.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * -----------------------------------------------------------------------------------------------
    **/
    @testSetup
    static void setup() {
        final Id userId = UserInfo.getUserId();

        final Account newAccount = arce.Arc_UtilitiesToTest_tst.crearCuentaGrupo('Test Account', null, 'G000001');
        insert newAccount;

        final List<arce__Analysis__c> newAnalyses = new List<arce__Analysis__c>();
        final arce__Analysis__c newAnalysis1 = arce.Arc_UtilitiesToTest_tst.crearArceAnalysis(
            'Test Analysis 1',
            null,
            newAccount.Id
        );
        newAnalysis1.arce__Stage__c = '1';
        newAnalysis1.arce__Is_Notified__c = false;
        newAnalysis1.arce__proposeUser__c = userId;
        newAnalyses.add(newAnalysis1);

        final arce__Analysis__c newAnalysis2 = arce.Arc_UtilitiesToTest_tst.crearArceAnalysis(
            'Test Analysis 2',
            null,
            newAccount.Id
        );
        newAnalysis2.arce__Stage__c = '2';
        newAnalysis2.arce__Is_Notified__c = false;
        newAnalysis2.arce__proposeUser__c = userId;
        newAnalyses.add(newAnalysis2);

        final arce__Analysis__c newAnalysis3 = arce.Arc_UtilitiesToTest_tst.crearArceAnalysis(
            'Test Analysis 3',
            null,
            newAccount.Id
        );
        newAnalysis3.arce__Stage__c = '2';
        newAnalysis3.arce__Is_Notified__c = false;
        newAnalysis3.arce__proposeUser__c = userId;
        newAnalyses.add(newAnalysis3);

        insert newAnalyses;

        final List<arce__Account_has_Analysis__c> newAhas = new List<arce__Account_has_Analysis__c>();
        final List<arce__Traceability_Event__c> newTraces = new List<arce__Traceability_Event__c>();
        for (arce__Analysis__c analysis : newAnalyses) {
            final arce__Account_has_Analysis__c newAha = new arce__Account_has_Analysis__c(
                arce__Analysis__c = analysis.Id,
                arce__IRP_Workflow__c = 'ARP'
            );
            newAhas.add(newAha);

            final arce__Traceability_Event__c newTrace = new arce__Traceability_Event__c(
                arce__analysis_id__c = analysis.Id,
                arce__current_event__c = true,
                arce__user_audit_id__c = userId,
                arce__gc_trcblty_internal_code_id__c = 'T-' + analysis.Id + '-0'
            );
            newTraces.add(newTrace);
        }
        insert newAhas;
        insert newTraces;

        // Modify arce__Analysis__c created dates to test the batch
        Test.setCreatedDate(newAnalyses[0].Id, Date.today().addDays(-105));
        Test.setCreatedDate(newAnalyses[1].Id, Date.today().addDays(-105));
        Test.setCreatedDate(newAnalyses[2].Id, Date.today().addDays(-91));
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Test the execute method from the batch class.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * -----------------------------------------------------------------------------------------------
    **/
    @isTest
    static void testExecuteBatch() {
        // WHEN
        Test.startTest();
        final Arc_Gen_AbandonedArce_Batch batch = new Arc_Gen_AbandonedArce_Batch();
        Database.executeBatch(batch);
        Test.stopTest();

        // THEN
        final List<EmailMessage> emails = [SELECT Id, ToAddress, Subject, TextBody FROM EmailMessage LIMIT 3];
        final List<arce__Analysis__c> notifiedAnalyses = [
            SELECT Id, arce__Is_Notified__c
            FROM arce__Analysis__c
            WHERE arce__Is_Notified__c = TRUE
        ];
        final List<arce__Analysis__c> canceledAnalyses = [
            SELECT Id, arce__Stage__c
            FROM arce__Analysis__c
            WHERE arce__Stage__c = '3'
        ];
        final List<Task> tasks = [SELECT Id FROM Task LIMIT 2];

        System.assert(
            emails.size() == 3 &&
                emails[0].ToAddress != null &&
                emails[0].Subject != null &&
                emails[0].TextBody != null &&
                notifiedAnalyses.size() == 1 &&
                canceledAnalyses.size() == 2 &&
                tasks.size() == 2,
            'All conditions should be met.'
        );
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Test the execute method from the batch class with a limit of emails
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * -----------------------------------------------------------------------------------------------
    **/
    @isTest
    static void testExecuteBatchLimitEmails() {
        // GIVEN
        final List<arce__Analysis__c> newAnalyses = new List<arce__Analysis__c>();
        for (Integer i = 0; i < 10; i++) {
            final arce__Analysis__c newAnalysis = arce.Arc_UtilitiesToTest_tst.crearArceAnalysis(
                'Test Analysis ' + i,
                null,
                null
            );
            newAnalysis.arce__Stage__c = '1';
            newAnalysis.arce__Is_Notified__c = false;
            newAnalyses.add(newAnalysis);
        }
        insert newAnalyses;

        for (Integer i = 0; i < 10; i++) {
            Test.setCreatedDate(newAnalyses[i].Id, Date.today().addDays(-105));
        }

        // WHEN
        Test.startTest();
        final Arc_Gen_AbandonedArce_Batch batch = new Arc_Gen_AbandonedArce_Batch();
        Database.executeBatch(batch);
        Test.stopTest();

        // THEN
        final List<Arc_Gen_AbandonedArce_Batch.JobError> jobErrors = batch.jobErrors;
        System.assertEquals(0, jobErrors.size(), 'There should be no job errors.');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Test the execute method from the batch class with no relations.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * -----------------------------------------------------------------------------------------------
    **/
    @isTest
    static void testExecuteBatchNoRelations() {
        // GIVEN
        delete [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__Analysis__r.Name LIKE 'Test Analysis%'];
        delete [SELECT Id FROM Account WHERE Name = 'Test Account'];

        // WHEN
        Test.startTest();
        final Arc_Gen_AbandonedArce_Batch batch = new Arc_Gen_AbandonedArce_Batch();
        Database.executeBatch(batch);
        Test.stopTest();

        // THEN
        final List<arce__Analysis__c> notifiedAnalyses = [
            SELECT Id, arce__Is_Notified__c
            FROM arce__Analysis__c
            WHERE arce__Is_Notified__c = TRUE
        ];
        final List<arce__Analysis__c> canceledAnalyses = [
            SELECT Id, arce__Stage__c
            FROM arce__Analysis__c
            WHERE arce__Stage__c = '3'
        ];

        System.assert(
            notifiedAnalyses.size() == 1 && canceledAnalyses.size() == 2,
            'There should be one analysis notified and two analyses canceled.'
        );
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Test the execute method from the batch class with an exception.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * -----------------------------------------------------------------------------------------------
    **/
    @isTest
    static void testExecuteBatchGenericException() {
        // GIVEN
        final Arc_Gen_AbandonedArce_Batch batch = new Arc_Gen_AbandonedArce_Batch();
        final List<SObject> scope = [SELECT Id FROM Account LIMIT 1];

        // WHEN
        Test.startTest();
        batch.execute(null, scope);
        Test.stopTest();

        // THEN
        final List<Arc_Gen_AbandonedArce_Batch.JobError> jobErrors = batch.jobErrors;
        System.assertEquals(1, jobErrors.size(), 'There should be one job error.');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Test the schedulable method from the batch class
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * -----------------------------------------------------------------------------------------------
    **/
    @isTest
    static void testSchedulable() {
        // WHEN
        Test.startTest();
        final String jobId = System.schedule('Test Schedule', cronExpression, new Arc_Gen_AbandonedArce_Batch());
        Test.stopTest();

        // THEN
        final CronTrigger cronTrigger = [
            SELECT Id, CronExpression, TimesTriggered, NextFireTime
            FROM CronTrigger
            WHERE Id = :jobId
        ];

        System.assert(
            cronExpression.equals(cronTrigger.CronExpression) &&
                0 == cronTrigger.TimesTriggered &&
                null != cronTrigger.NextFireTime,
            'Cron expression should match, TimesTriggered should be zero, and NextFireTime should not be null.'
        );
    }
}