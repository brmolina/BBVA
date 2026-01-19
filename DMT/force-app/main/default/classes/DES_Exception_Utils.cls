/**
 * @description       : Class that handles the storage of exception
 * @author            : Aníbal Cortés
 * @group             : 
 * @last modified on  : 12-30-2024
 * @last modified by  : Aníbal Cortés
**/
public with sharing class DES_Exception_Utils {
    
    public static boolean logException(Exception e, String className, String methodName, String projectCode, String objectName) {
        DES_Exceptions__b exc = createRegularException(e, className, methodName, projectCode, objectName);

        return insertImmediate(new List<DES_Exceptions__b>{exc});
    }

    public static boolean logExceptionList(List<Exception> exceptionList, String className, String methodName, String projectCode, String objectName) {
        List<DES_Exceptions__b> resultExceptionList = new List<DES_Exceptions__b>();
        for (Exception e : exceptionList) {
            DES_Exceptions__b exc = createRegularException(e, className, methodName, projectCode, objectName);
            resultExceptionList.add(exc);
        }
        return insertImmediate(resultExceptionList);
    }

    public static boolean logDesExceptionsList(List<DES_Exceptions__b> exceptionList) {
        List<DES_Exceptions__b> resultExceptionList = new List<DES_Exceptions__b>();
        resultExceptionList = exceptionList;
        return insertImmediate(resultExceptionList);
    }

    public static DES_Exceptions__b logExceptionWithoutInsert(Exception e, String className, String methodName, String projectCode, String objectName) {
        return createRegularException(e, className, methodName, projectCode, objectName);
    }

    public static List<DES_Exceptions__b> logExceptionListWithoutInsert(List<Exception> exceptionList, String className, String methodName, String projectCode, String objectName) {
        List<DES_Exceptions__b> resultExceptionList = new List<DES_Exceptions__b>();

        for (Exception e : exceptionList) {
            DES_Exceptions__b exc = createRegularException(e, className, methodName, projectCode, objectName);
            resultExceptionList.add(exc);
        }
        return resultExceptionList;
    }

    public static boolean logDMLException(Database.Error error, String className, String methodName, String projectCode, String objectName) {
        DES_Exceptions__b exc = createDMLException(error, className, methodName, projectCode, objectName);

        return insertImmediate(new List<DES_Exceptions__b>{exc});
    }

    public static boolean logDMLExceptionList(List<Database.Error> errorList, String className, String methodName, String projectCode, String objectName) {
        List<DES_Exceptions__b> resultExceptionList = new List<DES_Exceptions__b>();
        for (Database.Error error : errorList) {
            DES_Exceptions__b exc = createDMLException(error, className, methodName, projectCode, objectName);
            resultExceptionList.add(exc);
        }
        return insertImmediate(resultExceptionList);
    }


    public static DES_Exceptions__b logDMLExceptionWithoutInsert(Database.Error error, String className, String methodName, String projectCode, String objectName) {
        return createDMLException(error, className, methodName, projectCode, objectName);
    }

    public static List<DES_Exceptions__b> logDMLExceptionListWithoutInsert(List<Database.Error> errorList, String className, String methodName, String projectCode, String objectName) {
        List<DES_Exceptions__b> resultExceptionList = new List<DES_Exceptions__b>();

        for (Database.Error error : errorList) {
            DES_Exceptions__b exc = createDMLException(error, className, methodName, projectCode, objectName);
            resultExceptionList.add(exc);
        }
        return resultExceptionList;
    }

    private static boolean insertImmediate(List<DES_Exceptions__b> exceptions) {
        if (!Test.isRunningTest()) {
            Database.insertImmediate(exceptions);
        }

        return true;
    }


    private static DES_Exceptions__b createRegularException(Exception e, String className, String methodName, String projectCode, String objectName) {
        DES_Exceptions__b exc = new DES_Exceptions__b();
        exc.Project__c	= projectCode;
        exc.Class_Name__c = className;
        exc.Object__c = objectName;
        exc.Message__c = e.getMessage();
        exc.StackTrace__c = e.getStackTraceString();
        exc.MethodName__c = methodName;
        exc.LineNumber__c = e.getLineNumber();
        exc.Type__c = e.getTypeName();
        exc.Timestamp__c  = Datetime.now();
        exc.Reported_By__c   = UserInfo.getUserId();
        return exc;
    }

    private static DES_Exceptions__b createDMLException(Database.Error error, String className, String methodName, String projectCode, String objectName) {
        DES_Exceptions__b exc = new DES_Exceptions__b();
        exc.Project__c	= projectCode;
        exc.Class_Name__c = className;
        exc.Object__c = objectName;
        exc.Message__c = error.getMessage();
        exc.DML_Fields__c = error.getFields().toString();
        exc.MethodName__c = methodName;
        exc.Timestamp__c  = Datetime.now();
        exc.Reported_By__c   = UserInfo.getUserId();
        return exc;
    }    
    
}