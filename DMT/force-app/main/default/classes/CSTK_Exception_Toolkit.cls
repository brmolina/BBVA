/**
* ____________________________________________________________________________
* Toolkit Exception Sample
* Implementation of the interface cstk.Exception_Itf
* ____________________________________________________________________________
* @author      Manuel Canellas <manuel.canellas.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2025-06-06
* @modified
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
@SuppressWarnings('PMD.AvoidGlobalModifier')

/**
* @description Implementation of the interface cstk.Exception_Itf
*/
global with sharing class CSTK_Exception_Toolkit implements cstk.Exception_Itf {
    /**
    * @description Method to create error logs
    * @return boolean with the insert error
    * @param exceptionWrapperList
    */
    global static boolean logException(List<cstk.Exception_Wrapper> exceptionWrapperList) {
        Boolean insertResult = true;
        Database.SaveResult[] insertResutls;
        final List<DES_Exceptions__b> exceptionsRecords = createExceptionList(exceptionWrapperList);
        if (!Test.isRunningTest()) {//NOSONAR
            insertResutls = Database.insertImmediate(exceptionsRecords);
        }
        for (Integer index = 0; index < insertResutls?.size(); index++) {
            if (!insertResutls[index].isSuccess()) {
                insertResult = false;
            }
        }
        return insertResult;
    }

    /**
    * @description Method to create custom error logs
    * @return boolean with the insert error
    * @param exceptionWrapperList
    */
    global static boolean logCustomError(List<cstk.Exception_Wrapper> exceptionWrapperList) {
        Boolean insertResult = true;
        Database.SaveResult[] insertResutls;
        final List<DES_Exceptions__b> exceptionsRecords = createExceptionList(exceptionWrapperList);
        if (!Test.isRunningTest()) {//NOSONAR
            insertResutls = Database.insertImmediate(exceptionsRecords);
        }
        for (Integer index = 0; index < insertResutls?.size(); index++) {
            if (!insertResutls[index].isSuccess()) {
                insertResult = false;
            }
        }
        return insertResult;
    }

    /**
    * @description Method to create DES_Exceptions__b records
    * @return List<DES_Exceptions__b>
    * @param exceptionWrapperList
    */
    private static List<DES_Exceptions__b> createExceptionList(List<cstk.Exception_Wrapper> exceptionWrapperList) {
        final List<DES_Exceptions__b> exceptionList = new List<DES_Exceptions__b>();
        for(cstk.Exception_Wrapper exceptionWrapper : exceptionWrapperList) {
            final DES_Exceptions__b exc = new DES_Exceptions__b();
            exc.Project__c	= exceptionWrapper.projectCode;
            exc.Class_Name__c = exceptionWrapper.classNameOrCmp;
            exc.Object__c = exceptionWrapper.objectName;
            exc.MethodName__c = exceptionWrapper.methodName;
            exc.Timestamp__c  = Datetime.now();
            exc.Reported_By__c   = UserInfo.getUserId();
            exc.Message__c = exceptionWrapper.exceptionRecord?.getMessage() != null ? exceptionWrapper.exceptionRecord?.getMessage() : exceptionWrapper.message;
            exc.StackTrace__c = exceptionWrapper.exceptionRecord?.getStackTraceString();
            exc.LineNumber__c = exceptionWrapper.exceptionRecord?.getLineNumber();
            exc.Type__c = exceptionWrapper.exceptionRecord?.getTypeName();
            exceptionList.add(exc);
        }
        return exceptionList;
    }
}