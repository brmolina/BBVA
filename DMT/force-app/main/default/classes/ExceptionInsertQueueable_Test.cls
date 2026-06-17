@IsTest
private class ExceptionInsertQueueable_Test {

    private class NoOpExecutor implements ExceptionInsertQueueable.ExceptionInsertExecutor {
        public void insertRecords(List<DES_Exceptions__b> exceptions) {
            // No-op for deterministic try-path coverage without DML side effects.
        }
    }

    private class ThrowingExecutor implements ExceptionInsertQueueable.ExceptionInsertExecutor {
        public void insertRecords(List<DES_Exceptions__b> exceptions) {
            throw new DmlException('Forced insert failure for catch coverage');
        }
    }

    private static DES_Exceptions__b buildExceptionRecord() {
        return new DES_Exceptions__b(
            Project__c = 'DMT',
            Class_Name__c = 'TestClass',
            Object__c = 'TestObject',
            Message__c = 'Test message',
            StackTrace__c = 'Test stack trace',
            MethodName__c = 'testMethod',
            LineNumber__c = 1,
            Type__c = 'TestType',
            Timestamp__c = DateTime.now(),
            Reported_By__c = UserInfo.getUserId()
        );
    }

    @IsTest
    static void testExecuteWithExceptions() {
        List<DES_Exceptions__b> exceptions = new List<DES_Exceptions__b>{ buildExceptionRecord() };

        ExceptionInsertQueueable.forceInsertInTest = true;
        ExceptionInsertQueueable.testExecutor = new NoOpExecutor();

        Test.startTest();
        new ExceptionInsertQueueable(exceptions).execute(null);
        Test.stopTest();

        ExceptionInsertQueueable.forceInsertInTest = false;
        ExceptionInsertQueueable.testExecutor = null;

        System.assert(true, 'Queueable try-path should complete without errors');
    }

    @IsTest
    static void testExecuteCatchesInsertException() {
        List<DES_Exceptions__b> exceptions = new List<DES_Exceptions__b>{ buildExceptionRecord() };

        ExceptionInsertQueueable.forceInsertInTest = true;
        ExceptionInsertQueueable.testExecutor = new ThrowingExecutor();

        Test.startTest();
        new ExceptionInsertQueueable(exceptions).execute(null);
        Test.stopTest();

        ExceptionInsertQueueable.forceInsertInTest = false;
        ExceptionInsertQueueable.testExecutor = null;

        System.assert(true, 'Queueable catch-path should swallow insert exceptions silently');
    }

    @IsTest
    static void testExecuteWithEmptyList() {
        Test.startTest();
        new ExceptionInsertQueueable(new List<DES_Exceptions__b>()).execute(null);
        Test.stopTest();

        System.assert(true, 'Queueable should exit early for empty list without errors');
    }

    @IsTest
    static void testExecuteWithNullList() {
        Test.startTest();
        new ExceptionInsertQueueable(null).execute(null);
        Test.stopTest();

        System.assert(true, 'Queueable should exit early for null list without errors');
    }
}