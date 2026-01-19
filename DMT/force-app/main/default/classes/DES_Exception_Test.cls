/**
 * @description       : Clase test para clases derivadas de la funcionalidad de DES_Exception
 * @author            : Aníbal Cortés
 * @group             :
 * @last modified on  : 01-23-2025
 * @last modified by  : Aníbal Cortés
**/
@IsTest
public with sharing class DES_Exception_Test {
    
    @isTest
	static void logExceptionTest() {
        Exception exc = createException();
        Test.startTest();
        Boolean result = DES_Exception_Utils.logException(exc, 'DES_Exception_Test', 'logExceptionTest', 'DMT', 'Math');
        Test.stopTest();

        System.assertEquals(true, result, 'The result is true');
    }

    @isTest
	static void logExceptionListTest() {
        Exception exc = createException();
        Test.startTest();
        Boolean result = DES_Exception_Utils.logExceptionList(new List<Exception>{exc}, 'DES_Exception_Test', 'logExceptionTest', 'DMT', 'Math');
        Test.stopTest();

        System.assertEquals(true, result, 'The result is true');
    }

    @isTest
	static void logExceptionWithoutInsertTest() {
        Exception exc = createException();
        Test.startTest();
        DES_Exceptions__b exceptionReturned = DES_Exception_Utils.logExceptionWithoutInsert(exc, 'DES_Exception_Test', 'logExceptionTest', 'DMT', 'Math');
        Test.stopTest();

        System.assertEquals('my message', exceptionReturned.Message__c, 'It should be the same message');
    }

    @isTest
	static void logExceptionListWithoutInsertTest() {
        Exception exc = createException();
        Test.startTest();
        List<DES_Exceptions__b> exceptionReturned = DES_Exception_Utils.logExceptionListWithoutInsert(new List<Exception>{exc}, 'DES_Exception_Test', 'logExceptionTest', 'DMT', 'Math');
        Test.stopTest();

        System.assertEquals('my message', exceptionReturned.get(0).Message__c, 'It should be the same message');
    }

    @isTest
	static void logDMLExceptionTest() {
        Database.SaveResult[] results = createDMLException();
        Test.startTest();
        Boolean result = DES_Exception_Utils.logDMLException(results[0].getErrors()[0], 'DES_Exception_Test', 'logExceptionTest', 'DMT', 'Math');
        Test.stopTest();

        System.assertEquals(true, result, 'The result is true');
    }

    @isTest
	static void logDMLExceptionListTest() {
        Database.SaveResult[] results = createDMLException();
        Test.startTest();
        Boolean result = DES_Exception_Utils.logDMLExceptionList(results[0].getErrors(), 'DES_Exception_Test', 'logExceptionTest', 'DMT', 'Math');
        Test.stopTest();

        System.assertEquals(true, result, 'The result is true');
    }

    @isTest
	static void logDMLExceptionWithoutInsertTest() {
        Database.SaveResult[] results = createDMLException();
        Test.startTest();
        DES_Exceptions__b exceptionReturned = DES_Exception_Utils.logDMLExceptionWithoutInsert(results[0].getErrors()[0], 'DES_Exception_Test', 'logExceptionTest', 'DMT', 'Math');
        Test.stopTest();

        System.assertEquals('Required fields are missing: [Name]', exceptionReturned.Message__c, 'It should be the same message');
    }

    @isTest
	static void logDMLExceptionListWithoutInsertTest() {
        Database.SaveResult[] results = createDMLException();
        Test.startTest();
        List<DES_Exceptions__b> exceptionReturned = DES_Exception_Utils.logDMLExceptionListWithoutInsert(results[0].getErrors(), 'DES_Exception_Test', 'logExceptionTest', 'DMT', 'Math');
        Test.stopTest();

        System.assertEquals('Required fields are missing: [Name]', exceptionReturned.get(0).Message__c, 'It should be the same message');
    }


    private static Exception createException(){
        Exception exception1 = new System.MathException();
        exception1.setMessage('my message');

        return exception1;
    }

    private static Database.SaveResult[] createDMLException(){
        Account account = new Account();
        Database.saveResult[] results = Database.insert(new List<Account>{account}, false);

        return results;
    }
 
}