public class DMT_LogExceptionQueueable implements Queueable {
    private final List<DMT_LogExceptionPayload> exceptions;

    public DMT_LogExceptionQueueable(List<DMT_LogExceptionPayload> exceptions) {
        this.exceptions = exceptions;
    }

    public DMT_LogExceptionQueueable(String message, String stackTrace, Integer lineNumber, String typeName, String className, String methodName, String projectCode, String objectName) {
        this.exceptions = new List<DMT_LogExceptionPayload>{
            new DMT_LogExceptionPayload(message, stackTrace, lineNumber, typeName, className, methodName, projectCode, objectName)
        };
    }

    public void execute(QueueableContext context) {
        List<DES_Exceptions__b> excList = new List<DES_Exceptions__b>();

        for (DMT_LogExceptionPayload info : exceptions) {
            try {
                DES_Exceptions__b exc = new DES_Exceptions__b();
                exc.Project__c = info.projectCode;
                exc.Class_Name__c = info.className;
                exc.Object__c = info.objectName;
                exc.Message__c = info.message;
                exc.StackTrace__c = info.stackTrace;
                exc.MethodName__c = info.methodName;
                exc.LineNumber__c = info.lineNumber;
                exc.Type__c = info.typeName;
                exc.Timestamp__c = DateTime.now();
                exc.Reported_By__c = UserInfo.getUserId();

                excList.add(exc);
            } catch (Exception innerEx) {
                System.debug('Error preparing exception log: ' + innerEx.getMessage());
            }
        }

        if (!excList.isEmpty()) {
            DES_Exception_Utils.logDesExceptionsList(excList);
        }
    }
}