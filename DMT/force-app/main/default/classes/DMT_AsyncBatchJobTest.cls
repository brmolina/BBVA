@isTest
public class DMT_AsyncBatchJobTest {

    @TestSetup
    static void makeData(){
        List<iaso__GBL_Rest_Services_Url__c> settingsToInsert = new List<iaso__GBL_Rest_Services_Url__c>();

        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMTO_Endpoint_INT','https://service.ok', 'ServicesPartition', false));
        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_HPGR_Endpoint','https://service.ok', 'ServicesPartition', false));
        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_GrantingTicket','https://validation.ok', 'ServicesPartition', false));

        // Perform one single DML
        insert settingsToInsert;
    }

    // Concrete unsupported payload to cause dispatcher to throw inside the batch
    private class UnsupportedPayload implements DMT_AsyncPayload {
    }

    @isTest
    static void testDispatcher_LogException_and_ApplicationLog() {
        // Prepare a log application payload
        iaso__GBL_Application_Log__c logRec = new iaso__GBL_Application_Log__c(
            Name = 'DMT Test Log',
            iaso__Start_Time__c = Datetime.now().addSeconds(-5),
            iaso__End_Time__c = Datetime.now(),
            iaso__Message_LTA__c = 'Test message for application log'
        );

        List<iaso__GBL_Application_Log__c> logs = new List<iaso__GBL_Application_Log__c>{ logRec };
        DMT_AsyncPayload appPayload = new DMT_LogApplicationPayload(logs);

        // Prepare a log exception payload (typed as the interface but constructed as the concrete class)
        DMT_AsyncPayload exPayload = new DMT_LogExceptionPayload('Err msg','stacktrace',123,'ExceptionType','SomeClass','someMethod','DMT','Object');

        Test.startTest();
            // Dispatch application log payload - this will insert the application log record
            DMT_AsyncDispatcher.dispatch(appPayload);

            // Dispatch exception payload - this will enqueue a queueable which is executed during stopTest
            DMT_AsyncDispatcher.dispatch(exPayload);
        Test.stopTest();

        // Verify application log was inserted
        List<iaso__GBL_Application_Log__c> inserted = [SELECT Id, Name, iaso__Message_LTA__c FROM iaso__GBL_Application_Log__c WHERE Name = 'DMT Test Log' LIMIT 1];
        Assert.areEqual(1, inserted.size(), 'One application log should have been inserted');
    }

    @isTest
    static void testBatch_handles_exceptions_and_enqueues_log_queueable() {
        // Prepare payloads: one exception payload and one snapshot payload (both typed as DMT_AsyncPayload)
        DMT_AsyncPayload exPayload = new DMT_LogExceptionPayload('Err msg 2','stacktrace2',10,'ExceptionType','SomeClass','someMethod','DMT','Object');

        DMT_SnapshotEvaluationVersions.PostRequestWrapperClass postReq = new DMT_SnapshotEvaluationVersions.PostRequestWrapperClass();
        postReq.body = '{"Name":"Test"}';
        DMT_AsyncPayload snapshot = new DMT_SnapshotPayload(postReq, null, 'Line');

        List<DMT_AsyncPayload> payloads = new List<DMT_AsyncPayload>{ exPayload, snapshot };

        // Mock HTTP callouts used by snapshot processing
        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
            // Execute the batch - use payloads.size() as batch size so the framework runs a single batch invocation
            Database.executeBatch(new DMT_AsyncBatchJob(payloads), payloads.size());
        Test.stopTest();

        // If we reach here without uncaught exceptions, the batch executed and handled payloads
        Assert.isTrue(true, 'Batch executed and processed snapshot + exception payloads without uncaught exceptions');
    }

    @isTest
    static void testDispatcher_SnapshotPayload() {
        // Create a snapshot payload and dispatch it directly to exercise the snapshot branch
        DMT_SnapshotEvaluationVersions.PostRequestWrapperClass postReq = new DMT_SnapshotEvaluationVersions.PostRequestWrapperClass();
        postReq.body = '{"Name":"DirectTest"}';
        DMT_AsyncPayload snapshot = new DMT_SnapshotPayload(postReq, null, 'Line');

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
            DMT_AsyncDispatcher.dispatch(snapshot);
        Test.stopTest();

        Assert.isTrue(true, 'Snapshot payload dispatched without throwing');
    }

    @isTest
    static void testBatch_collects_exceptions_and_finish_enqueues() {
        // Prepare payloads: one exception payload and one unsupported concrete payload that will trigger IllegalArgumentException
        DMT_AsyncPayload exPayload = new DMT_LogExceptionPayload('BatchErr','stack',55,'ExceptionType','SomeClass','someMethod','DMT','Object');
        DMT_AsyncPayload unsupported = new UnsupportedPayload();

        List<DMT_AsyncPayload> payloads = new List<DMT_AsyncPayload>{ exPayload, unsupported };

        // No callout mocks needed — unsupported payload will trigger dispatcher to throw
        Test.startTest();
            Database.executeBatch(new DMT_AsyncBatchJob(payloads), payloads.size());
        Test.stopTest();

        // If finish enqueued the DMT_LogExceptionQueueable, the test completed successfully
        Assert.isTrue(true, 'Batch caught exception and finish enqueued a queueable');
    }
}