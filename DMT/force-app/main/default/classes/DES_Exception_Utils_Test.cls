@isTest
private class DES_Exception_Utils_Test {

    private static final String TEST_CLASS_NAME = 'TestClassName';
    private static final String TEST_METHOD_NAME = 'testMethodName';
    private static final String TEST_PROJECT_CODE = 'PRJ001';
    private static final String TEST_OBJECT_NAME = 'Account';

    @isTest
    static void testLogSingleException() {
        Test.startTest();
        Boolean result = DES_Exception_Utils.logException(
            new DmlException('Test DML Exception'),
            TEST_CLASS_NAME,
            TEST_METHOD_NAME,
            TEST_PROJECT_CODE,
            TEST_OBJECT_NAME
        );
        Test.stopTest();

        System.assertEquals(true, result, 'logException should return true.');
    }

    @isTest
    static void testLogExceptionList() {
        List<Exception> exceptions = new List<Exception>{
            new DmlException('Test DML Exception 1'),
            new NullPointerException() // CORREGIDO: Sin argumento String
        };

        Test.startTest();
        Boolean result = DES_Exception_Utils.logExceptionList(
            exceptions,
            TEST_CLASS_NAME,
            TEST_METHOD_NAME,
            TEST_PROJECT_CODE,
            TEST_OBJECT_NAME
        );
        Test.stopTest();

        System.assertEquals(true, result, 'logExceptionList should return true.');
    }
    
    @isTest
    static void testLogExceptionList_EmptyList() {
        List<Exception> exceptions = new List<Exception>();

        Test.startTest();
        Boolean result = DES_Exception_Utils.logExceptionList(
            exceptions,
            TEST_CLASS_NAME,
            TEST_METHOD_NAME,
            TEST_PROJECT_CODE,
            TEST_OBJECT_NAME
        );
        Test.stopTest();

        System.assertEquals(true, result, 'logExceptionList with empty list should return true.');
    }

    @isTest
    static void testLogDesExceptionsList() {
        List<DES_Exceptions__b> desExceptions = new List<DES_Exceptions__b>{
            DES_Exception_Utils.logExceptionWithoutInsert(new DmlException('Prebuilt Exception'), TEST_CLASS_NAME, TEST_METHOD_NAME, TEST_PROJECT_CODE, TEST_OBJECT_NAME)
        };

        Test.startTest();
        Boolean result = DES_Exception_Utils.logDesExceptionsList(desExceptions);
        Test.stopTest();

        System.assertEquals(true, result, 'logDesExceptionsList should return true.');
    }
    
    @isTest
    static void testLogDesExceptionsList_EmptyList() {
        List<DES_Exceptions__b> desExceptions = new List<DES_Exceptions__b>();

        Test.startTest();
        Boolean result = DES_Exception_Utils.logDesExceptionsList(desExceptions);
        Test.stopTest();

        System.assertEquals(true, result, 'logDesExceptionsList with empty list should return true.');
    }

    @isTest
    static void testLogExceptionWithoutInsert() {
        DmlException ex = new DmlException('Test DML Exception for No Insert');
        
        Test.startTest();
        DES_Exceptions__b resultExc = DES_Exception_Utils.logExceptionWithoutInsert(
            ex,
            TEST_CLASS_NAME,
            TEST_METHOD_NAME,
            TEST_PROJECT_CODE,
            TEST_OBJECT_NAME
        );
        Test.stopTest();

        System.assertNotEquals(null, resultExc, 'Resulting DES_Exceptions__b should not be null.');
        System.assertEquals(TEST_PROJECT_CODE, resultExc.Project__c);
        System.assertEquals(TEST_CLASS_NAME, resultExc.Class_Name__c);
        System.assertEquals(TEST_OBJECT_NAME, resultExc.Object__c);
        System.assertEquals(ex.getMessage(), resultExc.Message__c);
        System.assertEquals(ex.getStackTraceString(), resultExc.StackTrace__c);
        System.assertEquals(TEST_METHOD_NAME, resultExc.MethodName__c);
        System.assertEquals(ex.getTypeName(), resultExc.Type__c);
        System.assertNotEquals(null, resultExc.Timestamp__c);
        System.assertEquals(UserInfo.getUserId(), resultExc.Reported_By__c);
    }

        @isTest
    static void testLogExceptionListWithoutInsert() {
        List<Exception> exceptions = new List<Exception>{
            new DmlException('Test DML Exception 1 No Insert'),
            new NullPointerException() // Instanciado sin mensaje
        };

        Test.startTest();
        List<DES_Exceptions__b> resultList = DES_Exception_Utils.logExceptionListWithoutInsert(
            exceptions,
            TEST_CLASS_NAME,
            TEST_METHOD_NAME,
            TEST_PROJECT_CODE,
            TEST_OBJECT_NAME
        );
        Test.stopTest();

        System.assertNotEquals(null, resultList, 'Resulting list should not be null.');
        System.assertEquals(2, resultList.size(), 'Resulting list size should match input.');
        
        // Verificar la DmlException
        System.assertEquals(exceptions[0].getMessage(), resultList[0].Message__c);
        System.assertEquals(TEST_CLASS_NAME, resultList[0].Class_Name__c); // Asumimos que ambos usan el mismo className
        
        // Verificar la NullPointerException
        System.assertEquals(exceptions[1].getMessage(), resultList[1].Message__c);
        System.assertEquals('Script-thrown exception', resultList[1].Message__c, 'NullPointerException should have Script-thrown exception message.');
        System.assertEquals(TEST_CLASS_NAME, resultList[1].Class_Name__c);
        System.assertEquals(exceptions[1].getTypeName(), resultList[1].Type__c);
    }
    
    @isTest
    static void testLogExceptionListWithoutInsert_EmptyList() {
        List<Exception> exceptions = new List<Exception>();

        Test.startTest();
        List<DES_Exceptions__b> resultList = DES_Exception_Utils.logExceptionListWithoutInsert(
            exceptions,
            TEST_CLASS_NAME,
            TEST_METHOD_NAME,
            TEST_PROJECT_CODE,
            TEST_OBJECT_NAME
        );
        Test.stopTest();

        System.assertNotEquals(null, resultList, 'Resulting list should not be null.');
        System.assertEquals(0, resultList.size(), 'Resulting list should be empty.');
    }

    // Helper para generar Database.Error
    private static Database.Error generateTestError() {
        Database.SaveResult sr;
        Account acc = new Account(); 
        try {
            sr = Database.insert(acc, false); 
        } catch (Exception e) {
            System.debug('Error generating test DML error: ' + e.getMessage());
            System.assert(false, 'Setup for generating Database.Error failed: ' + e.getMessage());
            return null; 
        }
        
        System.assert(!sr.isSuccess(), 'SaveResult should indicate failure.');
        System.assert(sr.getErrors().size() > 0, 'SaveResult should contain errors.');
        return sr.getErrors()[0];
    }

    @isTest
    static void testLogDMLException() {
        Database.Error dbError = generateTestError();
        System.assertNotEquals(null, dbError, 'Database.Error should be generated.');

        Test.startTest();
        Boolean result = DES_Exception_Utils.logDMLException(
            dbError,
            TEST_CLASS_NAME,
            TEST_METHOD_NAME,
            TEST_PROJECT_CODE,
            TEST_OBJECT_NAME
        );
        Test.stopTest();

        System.assertEquals(true, result, 'logDMLException should return true.');
    }

    @isTest
    static void testLogDMLExceptionList() {
        List<Account> accountsToFail = new List<Account>{ new Account(), new Account() };
        List<Database.SaveResult> srs = Database.insert(accountsToFail, false);
        List<Database.Error> dbErrors = new List<Database.Error>();
        for (Database.SaveResult sr : srs) {
            if (!sr.isSuccess()) {
                dbErrors.addAll(sr.getErrors());
            }
        }
        System.assert(dbErrors.size() > 0, 'Should have generated DML errors.');

        Test.startTest();
        Boolean result = DES_Exception_Utils.logDMLExceptionList(
            dbErrors,
            TEST_CLASS_NAME,
            TEST_METHOD_NAME,
            TEST_PROJECT_CODE,
            TEST_OBJECT_NAME
        );
        Test.stopTest();

        System.assertEquals(true, result, 'logDMLExceptionList should return true.');
    }

    @isTest
    static void testLogDMLExceptionList_EmptyList() {
        List<Database.Error> dbErrors = new List<Database.Error>();

        Test.startTest();
        Boolean result = DES_Exception_Utils.logDMLExceptionList(
            dbErrors,
            TEST_CLASS_NAME,
            TEST_METHOD_NAME,
            TEST_PROJECT_CODE,
            TEST_OBJECT_NAME
        );
        Test.stopTest();

        System.assertEquals(true, result, 'logDMLExceptionList with empty list should return true.');
    }


    @isTest
    static void testLogDMLExceptionWithoutInsert() {
        Database.Error dbError = generateTestError();
        System.assertNotEquals(null, dbError, 'Database.Error should be generated.');
        
        Test.startTest();
        DES_Exceptions__b resultExc = DES_Exception_Utils.logDMLExceptionWithoutInsert(
            dbError,
            TEST_CLASS_NAME,
            TEST_METHOD_NAME,
            TEST_PROJECT_CODE,
            TEST_OBJECT_NAME
        );
        Test.stopTest();

        System.assertNotEquals(null, resultExc, 'Resulting DES_Exceptions__b should not be null.');
        System.assertEquals(TEST_PROJECT_CODE, resultExc.Project__c);
        System.assertEquals(TEST_CLASS_NAME, resultExc.Class_Name__c);
        System.assertEquals(TEST_OBJECT_NAME, resultExc.Object__c);
        System.assertEquals(dbError.getMessage(), resultExc.Message__c);
        System.assertEquals(String.valueOf(dbError.getFields()), resultExc.DML_Fields__c); // getFields() devuelve List<String>
        System.assertEquals(TEST_METHOD_NAME, resultExc.MethodName__c);
        System.assertNotEquals(null, resultExc.Timestamp__c);
        System.assertEquals(UserInfo.getUserId(), resultExc.Reported_By__c);
    }

    @isTest
    static void testLogDMLExceptionListWithoutInsert() {
        List<Account> accountsToFail = new List<Account>{ new Account(), new Account() };
        List<Database.SaveResult> srs = Database.insert(accountsToFail, false);
        List<Database.Error> dbErrors = new List<Database.Error>();
        for (Database.SaveResult sr : srs) {
            if (!sr.isSuccess()) {
                dbErrors.addAll(sr.getErrors());
            }
        }
        System.assert(dbErrors.size() > 0, 'Should have generated DML errors.');

        Test.startTest();
        List<DES_Exceptions__b> resultList = DES_Exception_Utils.logDMLExceptionListWithoutInsert(
            dbErrors,
            TEST_CLASS_NAME,
            TEST_METHOD_NAME,
            TEST_PROJECT_CODE,
            TEST_OBJECT_NAME
        );
        Test.stopTest();

        System.assertNotEquals(null, resultList, 'Resulting list should not be null.');
        System.assertEquals(dbErrors.size(), resultList.size(), 'Resulting list size should match input.');
        if (!resultList.isEmpty()) {
             System.assertEquals(dbErrors[0].getMessage(), resultList[0].Message__c);
             System.assertEquals(TEST_CLASS_NAME, resultList[0].Class_Name__c);
        }
    }
    
    @isTest
    static void testLogDMLExceptionListWithoutInsert_EmptyList() {
        List<Database.Error> dbErrors = new List<Database.Error>();

        Test.startTest();
        List<DES_Exceptions__b> resultList = DES_Exception_Utils.logDMLExceptionListWithoutInsert(
            dbErrors,
            TEST_CLASS_NAME,
            TEST_METHOD_NAME,
            TEST_PROJECT_CODE,
            TEST_OBJECT_NAME
        );
        Test.stopTest();

        System.assertNotEquals(null, resultList, 'Resulting list should not be null.');
        System.assertEquals(0, resultList.size(), 'Resulting list should be empty for empty input.');
    }
}