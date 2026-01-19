/**
* @description
*/
@isTest
public with sharing class CSTK_Exception_Toolkit_Test {
    /**
    * @description
    */
    @isTest static void logExceptionTest() {
        Test.startTest();
        final List<cstk.Exception_Wrapper> excWrapperList = new List<cstk.Exception_Wrapper>();
        excWrapperList.add(new cstk.Exception_Wrapper(null, 'apexLogTest', 'createExceptionError', 'toolkit', 'Account', 'Error message' ));
        final Boolean result = CSTK_Exception_Toolkit.logException(excWrapperList);
        System.assert(result, 'OK');
        Test.stopTest();
    }

    /**
    * @description
    */
    @isTest static void logCustomError() {
        Test.startTest();
        final List<cstk.Exception_Wrapper> excWrapperList = new List<cstk.Exception_Wrapper>();
        excWrapperList.add(new cstk.Exception_Wrapper(null, 'apexLogTest', 'createExceptionError', 'toolkit', 'Account', 'Error message' ));
        final Boolean result = CSTK_Exception_Toolkit.logCustomError(excWrapperList);
        System.assert(result, 'OK');
        Test.stopTest();
    }

}