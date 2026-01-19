/**
 * @description       : Test class for DMT_Des_ExceptionViewerController
 * @author            : Javier Portilla
 * @group             : 
 * @last modified on  : 03-14-2025
 * @last modified by  : Javier Portilla
**/
@isTest
private class DMT_Des_ExceptionViewerControllerTest {

    @isTest
    static void logError() {
        Exception exc = createException();
        Test.startTest();
        Boolean result = DES_Exception_Utils.logException(exc, 'DES_Exception_Test', 'logExceptionTest', 'DMT', 'Math');
        Test.stopTest();
        System.assertEquals(true, result, 'The result is true');
    }

    @isTest
    static void testGetRecords() {
        Exception exc = createException();
        DES_Exception_Utils.logException(exc, 'DES_Exception_Test', 'logExceptionTest', 'DMT', 'Math');
        Test.startTest();
        List<DES_Exceptions__b> result = DMT_Des_ExceptionViewerController.getRecords(
            System.today().addDays(-1), System.today().addDays(1), 10, System.now()
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'The result should not be null');
    }

    private static Exception createException(){
        Exception exception1 = new System.MathException();
        exception1.setMessage('my message');

        return exception1;
    }

}