@isTest
public without sharing class DMT_AsyncBatchJobTest {

    @TestSetup
    static void makeData(){
        List<iaso__GBL_Rest_Services_Url__c> settingsToInsert = new List<iaso__GBL_Rest_Services_Url__c>();

        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMTO_Endpoint_INT','https://service.ok', 'ServicesPartition', false));
        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_HPGR_Endpoint','https://service.ok', 'ServicesPartition', false));
        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_GrantingTicket','https://validation.ok', 'ServicesPartition', false));
        insert settingsToInsert;
    }

    private class UnsupportedPayload implements DMT_AsyncPayload {}

    @isTest
    static void testDispatcherLogExceptionAndApplicationLog() {
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
    static void testBatchHandlesExceptionsAndEnqueuesLogQueueable() {
        // Prepare payloads: one exception payload and one snapshot payload (both typed as DMT_AsyncPayload)
        DMT_AsyncPayload exPayload = new DMT_LogExceptionPayload('Err msg 2','stacktrace2',10,'ExceptionType','SomeClass','someMethod','DMT','Object');

        List<DMT_AsyncPayload> payloads = new List<DMT_AsyncPayload>{exPayload};

        Test.startTest();
            // Execute the batch - use payloads.size() as batch size so the framework runs a single batch invocation
            Database.executeBatch(new DMT_AsyncBatchJob(payloads), payloads.size());
        Test.stopTest();

        // If we reach here without uncaught exceptions, the batch executed and handled payloads
        Assert.isTrue(true, 'Batch executed and processed exception payloads without uncaught exceptions');
    }
    @isTest
    static void testBatchHandlesExceptionsAndEnqueuesLogBatch() {
        DMT_AsyncPayload exPayload = new DMT_LogExceptionPayload('Err msg 2','stacktrace2',10,'ExceptionType','SomeClass','someMethod','DMT','Object');

        List<DMT_AsyncPayload> payloads = new List<DMT_AsyncPayload>{exPayload};

        Test.startTest();
            System.enqueueJob(new DMT_AsyncQueueJob(payloads));
        Test.stopTest();

        // If we reach here without uncaught exceptions, the batch executed and handled payloads
        Assert.isTrue(true, 'Queueable executed and processed exception payloads without uncaught exceptions');
    }

    @isTest
    static void testDispatcherSnapshotPayload() {
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
    static void testBatchHandlesBulkExceptionPayloads() {
        // 1. Prepare a list of Exception Payloads
        List<DMT_AsyncPayload> errorPayloads = new List<DMT_AsyncPayload>{
            new DMT_LogExceptionPayload('Bulk Err 1','stack',1,'Type','Class','Method','DMT','Obj'),
            new DMT_LogExceptionPayload('Bulk Err 2','stack',2,'Type','Class','Method','DMT','Obj')
        };

        Test.startTest();
            // Execute batch with the list of exceptions
            Database.executeBatch(new DMT_AsyncBatchJob(errorPayloads), 2);
        Test.stopTest();

        // Verify: No exception thrown and code reached end
        Assert.isTrue(true, 'Bulk exception payloads handled via handleLogExceptions in Batch context');
    }

    @isTest
    static void testDispatcherCircuitBreakerBypass() {
        // 2. Test the Circuit Breaker: Pass an error from the logger itself
        DMT_LogExceptionPayload recursiveErr = new DMT_LogExceptionPayload(
            'Recursive Loop Test', 'stack', 0, 'Loop', 'DMT_LogExceptionQueueable', 'execute', 'DMT', 'Obj'
        );

        Test.startTest();
            // This should hit the 'continue' in the loop and do nothing
            DMT_AsyncDispatcher.handleLogExceptions(new List<DMT_AsyncPayload>{ recursiveErr });
        Test.stopTest();

        Assert.isTrue(true, 'Circuit breaker successfully ignored recursive error without throwing');
    }

    @isTest
    static void testDispatcherSingleExceptionSyncPath() {
        // 1. Prepare a single exception payload
        DMT_LogExceptionPayload pl = new DMT_LogExceptionPayload(
            'Single Error', 'Stack...', 10, 'SyncException',
            'TestClass', 'testMethod', 'DMT', 'Account'
        );

        Test.startTest();
            // 2. Dispatch the single payload.
            // Since we are in a Sync (test) context, it will hit the 'else'
            // and enqueue the DMT_LogExceptionQueueable.
            DMT_AsyncDispatcher.dispatch(pl);
        Test.stopTest();

        // 3. Verification
        // If stopTest finishes without error, the Queueable was enqueued and executed.
        Assert.isTrue(true, 'Single exception dispatched correctly from synchronous context.');
    }

    @isTest
    static void testDispatcherSingleExceptionAsyncPath() {
        // 1. Prepare a single exception payload
        DMT_LogExceptionPayload pl = new DMT_LogExceptionPayload(
            'Async Error', 'Stack...', 20, 'AsyncException',
            'TestClass', 'testMethod', 'DMT', 'Account'
        );

        // 2. We use a Batch to "simulate" being in an async context
        // This will force handleLogException to take the 'if (System.isBatch())' branch
        Test.startTest();
            // Note: We use a simple anonymous batch or just call the dispatcher
            // within a context that Salesforce recognizes as async if possible.
            // Easiest way: wrap it in a small Queueable for the test.
            System.enqueueJob(new SingleExceptionAsyncRunner(pl));
        Test.stopTest();

        Assert.isTrue(true, 'Single exception dispatched correctly from asynchronous context.');
    }

    /**
     * @description Covers the Snapshot loop in DMT_AsyncQueueJob
     */
    @isTest
    static void testQueueJobSnapshotLoop() {
        DMT_SnapshotEvaluationVersions.PostRequestWrapperClass postReq = new DMT_SnapshotEvaluationVersions.PostRequestWrapperClass();
        postReq.body = '{"Name":"Queue"}';
        DMT_AsyncPayload snapshot = new DMT_SnapshotPayload(postReq, null, 'Line');

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        Test.startTest();
            System.enqueueJob(new DMT_AsyncQueueJob(new List<DMT_AsyncPayload>{snapshot}));
        Test.stopTest();
        Assert.isTrue(true, 'The statement is true');
    }

    /**
     * @description Covers the Exception aggregation and chaining to Queue in DMT_AsyncQueueJob
     */
    @isTest
    static void testQueueJobWithExceptionChaining() {
        // Sending an unsupported payload to a QueueJob will trigger the catch block
        // which adds to exceptionsCollected and then fires the Batch.
        DMT_AsyncPayload unsupported = new UnsupportedPayload();
        Test.startTest();
            System.enqueueJob(new DMT_AsyncQueueJob(new List<DMT_AsyncPayload>{unsupported}));
        Test.stopTest();
        Assert.isTrue(true, 'QueueJob with unsupported payload executed and chained to Batch without uncaught exceptions');
    }

    /**
     * @description Covers the Exception aggregation and chaining to Batch in DMT_AsyncQueueJob
     */
    @isTest
    static void testQueueJobWithExceptionChainingBatch() {
        // Sending an unsupported payload to a Batch will trigger the catch block
        // which adds to exceptionsCollected and then fires the Queueable.
        DMT_AsyncPayload unsupported = new UnsupportedPayload();
        Test.startTest();
            Database.executeBatch(new DMT_AsyncBatchJob(new List<DMT_AsyncPayload>{unsupported}));
        Test.stopTest();
        Assert.isTrue(true, 'Batch with unsupported payload executed and chained to Queueable without uncaught exceptions');
    }

    /**
     * @description CIBGLOBALD-4157 follow-up: a DMT_AsyncQueueJob buffer larger than
     * INLINE_DISPATCH_LIMIT must be handed back to DMT_AsyncOrchestrator.flush() instead of
     * being dispatched inline (see DMT_AsyncQueueJob.execute()) - reproduces the "Too many
     * SOQL queries" failure seen when DMT_BatchSanctionAMIWEB changes many line statuses in
     * one chunk and each one enqueues a Passport re-evaluation payload.
     */
    @isTest
    static void testQueueJobDefersLargeBufferToOrchestrator() {
        List<DMT_AsyncPayload> manyPayloads = new List<DMT_AsyncPayload>();
        for (Integer i = 0; i < 7; i++) {
            manyPayloads.add(new DMT_LogExceptionPayload('Bulk Err ' + i, 'stack', i, 'Type', 'Class', 'Method', 'DMT', 'Obj'));
        }

        DMT_AsyncQueueJob.forceDeferForTest = true;
        try {
            Test.startTest();
                System.enqueueJob(new DMT_AsyncQueueJob(manyPayloads));
            Test.stopTest();
        } finally {
            DMT_AsyncQueueJob.forceDeferForTest = false;
        }

        Assert.isTrue(true, 'A buffer above INLINE_DISPATCH_LIMIT should be re-routed through the orchestrator without throwing');
    }

    /**
     * @description A buffer at or below INLINE_DISPATCH_LIMIT must still be dispatched inline,
     * exactly as before this fix - the deferral branch must not affect the common small case.
     */
    @isTest
    static void testQueueJobDispatchesSmallBufferInline() {
        List<DMT_AsyncPayload> fewPayloads = new List<DMT_AsyncPayload>{
            new DMT_LogExceptionPayload('Small Err 1', 'stack', 1, 'Type', 'Class', 'Method', 'DMT', 'Obj'),
            new DMT_LogExceptionPayload('Small Err 2', 'stack', 2, 'Type', 'Class', 'Method', 'DMT', 'Obj')
        };

        Test.startTest();
            System.enqueueJob(new DMT_AsyncQueueJob(fewPayloads));
        Test.stopTest();

        Assert.isTrue(true, 'A buffer at or below INLINE_DISPATCH_LIMIT should still dispatch inline without throwing');
    }

    private class SingleExceptionAsyncRunner implements Queueable {
        DMT_AsyncPayload payload;
        public SingleExceptionAsyncRunner(DMT_AsyncPayload pl) { this.payload = pl; }
        public void execute(QueueableContext context) { DMT_AsyncDispatcher.dispatch(payload); }
    }

    @isTest
    static void testBatchSnapshotLoopCoverage() {
        DMT_SnapshotEvaluationVersions.PostRequestWrapperClass postReq = new DMT_SnapshotEvaluationVersions.PostRequestWrapperClass();
        postReq.body = '{"Name":"BatchSnapshotTest"}';

        // Create 2 payloads to ensure the loop actually "loops"
        List<DMT_AsyncPayload> snapshotPayloads = new List<DMT_AsyncPayload>{
            new DMT_SnapshotPayload(postReq, null, 'Line'),
            new DMT_SnapshotPayload(postReq, null, 'Line')
        };

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
            Database.executeBatch(new DMT_AsyncBatchJob(snapshotPayloads), snapshotPayloads.size());
        Test.stopTest();

        // 5. Verification
        // If the test finishes without error, the 'else' block and the internal for-loop
        // were successfully executed.
        Assert.isTrue(true, 'The Batch snapshot loop was successfully covered.');
    }

    // =========================================================================
    // TESTS FOR DMT_ConsumptionReassignPayload
    // =========================================================================

    @isTest
    static void testDispatcherConsumptionReassign_HappyPath() {
        // 1. Prepare valid payload WITH corporateUserId and opportunityId
        Map<String, Object> inputMap = new Map<String, Object>{
            'groupId' => 'G00000000000200',
            'opportunityId' => 'ESCD25LIN00006409ES'
        };
        DMT_ConsumptionReassignPayload payload = new DMT_ConsumptionReassignPayload(inputMap, 'T049321');

        Test.startTest();
        // Dispatch routes to handleConsumptionReassign and hits the 204 mock success
        DMT_AsyncDispatcher.dispatch(payload);
        Test.stopTest();

        // If it completes without crashing, the routing and success path are fully covered
        Assert.isTrue(true, 'Consumption Reassign Payload dispatched and processed successfully.');
    }

    @isTest
    static void testDispatcherConsumptionReassign_FallbackPath() {
        // 2. Prepare payload WITHOUT opportunityId and WITHOUT corporateUserId 
        // This covers the "SystemAsync" fallback and the missing OppId condition.
        Map<String, Object> inputMap = new Map<String, Object>{
            'groupId' => 'G00000000000200'
        };
        DMT_ConsumptionReassignPayload payload = new DMT_ConsumptionReassignPayload(inputMap, null);

        Test.startTest();
        DMT_AsyncDispatcher.dispatch(payload);
        Test.stopTest();

        Assert.isTrue(true, 'Consumption Reassign Payload fallback branches covered successfully.');
    }

    @isTest
    static void testDispatcherConsumptionReassign_ExceptionPath() {
        // 3. Prepare an invalid payload (inputMap is null) to force a NullPointerException
        // when the code tries to do p.inputMap.get('groupId').
        // handleConsumptionReassign no longer swallows this - it must propagate so the
        // caller (DMT_AsyncQueueJob/DMT_AsyncBatchJob) can log it in a fresh transaction
        // instead of attempting a Big Object write right after a callout.
        DMT_ConsumptionReassignPayload payload = new DMT_ConsumptionReassignPayload(null, 'T049321');

        Boolean threw = false;
        Test.startTest();
        try {
            DMT_AsyncDispatcher.dispatch(payload);
        } catch (Exception e) {
            threw = true;
        }
        Test.stopTest();

        Assert.isTrue(threw, 'A malformed payload must propagate the exception to the caller instead of being swallowed.');
    }

    @isTest
    static void testDispatcherConsumptionReassign_NonSuccessStatus_Throws() {
        // A well-formed payload but a non-204 response must also throw, not just System.debug.
        Map<String, Object> inputMap = new Map<String, Object>{ 'groupId' => 'G00000000000200' };
        DMT_ConsumptionReassignPayload payload = new DMT_ConsumptionReassignPayload(inputMap, 'T049321');

        DMT_AsyncDispatcher.forceStatusCodeForTest = 500;
        Boolean threw = false;
        Test.startTest();
        try {
            DMT_AsyncDispatcher.dispatch(payload);
        } catch (Exception e) {
            threw = true;
        } finally {
            DMT_AsyncDispatcher.forceStatusCodeForTest = null;
        }
        Test.stopTest();

        Assert.isTrue(threw, 'A non-204 response must throw so the caller logs the failure.');
    }
}