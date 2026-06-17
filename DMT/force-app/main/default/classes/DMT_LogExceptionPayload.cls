public with sharing class DMT_LogExceptionPayload implements DMT_AsyncPayload {
    public String message { get; set; }
    public String stackTrace { get; set; }
    public Integer lineNumber { get; set; }
    public String typeName { get; set; }
    public String className { get; set; }
    public String methodName { get; set; }
    public String projectCode { get; set; }
    public String objectName { get; set; }

    public DMT_LogExceptionPayload(String message, String stackTrace, Integer lineNumber, String typeName,
                                   String className, String methodName, String projectCode, String objectName) {
        this.message = message;
        this.stackTrace = stackTrace;
        this.lineNumber = lineNumber;
        this.typeName = typeName;
        this.className = className;
        this.methodName = methodName;
        this.projectCode = projectCode;
        this.objectName = objectName;
    }
}