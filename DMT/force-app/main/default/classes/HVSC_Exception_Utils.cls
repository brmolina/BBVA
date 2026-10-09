/**
 * @description Centralized HVSC exception logging utility.
 *              Builds normalized DES_Exceptions__b entries for Apex, trigger services,
 *              batches, queueables, futures, Flow actions, and LWC controllers.
 *              Non-trigger callers are persisted with Database.insertImmediate.
 *              Trigger callers are dispatched to ExceptionInsertQueueable to avoid mixing
 *              Big Object DML with sObject DML in the trigger transaction.
 * @author Borja Lorenzo Adajas
 * @date 2026-06-30
 */
public with sharing class HVSC_Exception_Utils {

    private static final String CLASSNAME = 'HVSC_Exception_Utils';
    private static final String DEFAULT_PROJECT_CODE = 'HVSC';
    private static final String DEFAULT_TYPE = 'Apex';
    private static final String EMPTY_VALUE = '';
    private static final Integer TEXT_FIELD_MAX_LENGTH = 255;
    private static final Integer LONG_TEXT_FIELD_MAX_LENGTH = 32768;
    private static Long lastTimestampMillis;

    /** Allows tests to execute the persistence path instead of stopping after normalization. */
    @TestVisible private static Boolean forceInsertInTest = false;

    /**
     * @description Logs a single Apex exception without a related record id.
     * @param e Exception captured by the caller.
     * @param className Class where the exception was captured.
     * @param methodName Method where the exception was captured.
     * @param projectCode Project code used to group the log. Defaults to HVSC when blank.
     * @param objectName Related SObject API name, or blank when not applicable.
     * @return True when the log is accepted or skipped for a null exception; false only when persistence fails.
     */
    public static Boolean logException(Exception e, String className, String methodName, String projectCode, String objectName) {
        return logException(e, className, methodName, projectCode, objectName, null);
    }

    /**
     * @description Logs a single Apex exception and optionally stores the related record id.
     * @param e Exception captured by the caller.
     * @param className Class where the exception was captured.
     * @param methodName Method where the exception was captured.
     * @param projectCode Project code used to group the log. Defaults to HVSC when blank.
     * @param objectName Related SObject API name, or blank when not applicable.
     * @param recordId Related Salesforce record id, or null when not applicable.
     * @return True when the log is accepted or skipped for a null exception; false only when persistence fails.
     */
    public static Boolean logException(Exception e, String className, String methodName, String projectCode, String objectName, Id recordId) {
        if (e == null) {
            return true;
        }

        DES_Exceptions__b exc = createRegularException(e, className, methodName, projectCode, objectName, recordId, getNextTimestamp());
        return insertImmediate(new List<DES_Exceptions__b>{ exc });
    }

    /**
     * @description Logs a list of Apex exceptions without a related record id.
     * @param exceptionList Exceptions captured by the caller.
     * @param className Class where the exceptions were captured.
     * @param methodName Method where the exceptions were captured.
     * @param projectCode Project code used to group the logs. Defaults to HVSC when blank.
     * @param objectName Related SObject API name, or blank when not applicable.
     * @return True when the list is accepted or empty; false only when persistence fails.
     */
    public static Boolean logExceptionList(List<Exception> exceptionList, String className, String methodName, String projectCode, String objectName) {
        return logExceptionList(exceptionList, className, methodName, projectCode, objectName, null);
    }

    /**
     * @description Logs a list of Apex exceptions and optionally stores the related record id in each entry.
     * @param exceptionList Exceptions captured by the caller.
     * @param className Class where the exceptions were captured.
     * @param methodName Method where the exceptions were captured.
     * @param projectCode Project code used to group the logs. Defaults to HVSC when blank.
     * @param objectName Related SObject API name, or blank when not applicable.
     * @param recordId Related Salesforce record id, or null when not applicable.
     * @return True when the list is accepted or empty; false only when persistence fails.
     */
    public static Boolean logExceptionList(List<Exception> exceptionList, String className, String methodName, String projectCode, String objectName, Id recordId) {
        List<DES_Exceptions__b> resultExceptionList = new List<DES_Exceptions__b>();
        if (exceptionList == null || exceptionList.isEmpty()) {
            return true;
        }

        for (Exception e : exceptionList) {
            if (e == null) {
                continue;
            }
            resultExceptionList.add(createRegularException(
                e,
                className,
                methodName,
                projectCode,
                objectName,
                recordId,
                getNextTimestamp()
            ));
        }
        return insertImmediate(resultExceptionList);
    }

    /**
     * @description Persists prebuilt DES_Exceptions__b records after applying required defaults and length normalization.
     * @param exceptionList Prebuilt Big Object entries to persist.
     * @return True when the list is accepted or empty; false only when persistence fails.
     */
    public static Boolean logDesExceptionsList(List<DES_Exceptions__b> exceptionList) {
        return insertImmediate(exceptionList);
    }

    /**
     * @description Builds a DES_Exceptions__b entry from a single Apex exception without persisting it.
     * @param e Exception captured by the caller.
     * @param className Class where the exception was captured.
     * @param methodName Method where the exception was captured.
     * @param projectCode Project code used to group the log. Defaults to HVSC when blank.
     * @param objectName Related SObject API name, or blank when not applicable.
     * @return Normalized DES_Exceptions__b entry, or null when the exception is null.
     */
    public static DES_Exceptions__b logExceptionWithoutInsert(Exception e, String className, String methodName, String projectCode, String objectName) {
        return logExceptionWithoutInsert(e, className, methodName, projectCode, objectName, null);
    }

    /**
     * @description Builds a DES_Exceptions__b entry from a single Apex exception without persisting it.
     * @param e Exception captured by the caller.
     * @param className Class where the exception was captured.
     * @param methodName Method where the exception was captured.
     * @param projectCode Project code used to group the log. Defaults to HVSC when blank.
     * @param objectName Related SObject API name, or blank when not applicable.
     * @param recordId Related Salesforce record id, or null when not applicable.
     * @return Normalized DES_Exceptions__b entry, or null when the exception is null.
     */
    public static DES_Exceptions__b logExceptionWithoutInsert(Exception e, String className, String methodName, String projectCode, String objectName, Id recordId) {
        if (e == null) {
            return null;
        }
        return createRegularException(e, className, methodName, projectCode, objectName, recordId, getNextTimestamp());
    }

    /**
     * @description Builds DES_Exceptions__b entries from Apex exceptions without persisting them.
     * @param exceptionList Exceptions captured by the caller.
     * @param className Class where the exceptions were captured.
     * @param methodName Method where the exceptions were captured.
     * @param projectCode Project code used to group the logs. Defaults to HVSC when blank.
     * @param objectName Related SObject API name, or blank when not applicable.
     * @return Normalized DES_Exceptions__b entries. Empty when the input is null or empty.
     */
    public static List<DES_Exceptions__b> logExceptionListWithoutInsert(List<Exception> exceptionList, String className, String methodName, String projectCode, String objectName) {
        return logExceptionListWithoutInsert(exceptionList, className, methodName, projectCode, objectName, null);
    }

    /**
     * @description Builds DES_Exceptions__b entries from Apex exceptions without persisting them.
     * @param exceptionList Exceptions captured by the caller.
     * @param className Class where the exceptions were captured.
     * @param methodName Method where the exceptions were captured.
     * @param projectCode Project code used to group the logs. Defaults to HVSC when blank.
     * @param objectName Related SObject API name, or blank when not applicable.
     * @param recordId Related Salesforce record id, or null when not applicable.
     * @return Normalized DES_Exceptions__b entries. Empty when the input is null or empty.
     */
    public static List<DES_Exceptions__b> logExceptionListWithoutInsert(List<Exception> exceptionList, String className, String methodName, String projectCode, String objectName, Id recordId) {
        List<DES_Exceptions__b> resultExceptionList = new List<DES_Exceptions__b>();
        if (exceptionList == null || exceptionList.isEmpty()) {
            return resultExceptionList;
        }

        for (Exception e : exceptionList) {
            if (e == null) {
                continue;
            }
            resultExceptionList.add(createRegularException(
                e,
                className,
                methodName,
                projectCode,
                objectName,
                recordId,
                getNextTimestamp()
            ));
        }
        return resultExceptionList;
    }

    /**
     * @description Logs a single Database.Error produced by partial DML without a related record id.
     * @param error Database.Error returned by Database.insert, update, upsert, delete, or undelete with allOrNone=false.
     * @param className Class where the DML error was captured.
     * @param methodName Method where the DML error was captured.
     * @param projectCode Project code used to group the log. Defaults to HVSC when blank.
     * @param objectName Related SObject API name, or blank when not applicable.
     * @return True when the log is accepted or skipped for a null error; false only when persistence fails.
     */
    public static Boolean logDMLException(Database.Error error, String className, String methodName, String projectCode, String objectName) {
        return logDMLException(error, className, methodName, projectCode, objectName, null);
    }

    /**
     * @description Logs a single Database.Error produced by partial DML and optionally stores the related record id.
     * @param error Database.Error returned by Database.insert, update, upsert, delete, or undelete with allOrNone=false.
     * @param className Class where the DML error was captured.
     * @param methodName Method where the DML error was captured.
     * @param projectCode Project code used to group the log. Defaults to HVSC when blank.
     * @param objectName Related SObject API name, or blank when not applicable.
     * @param recordId Related Salesforce record id, or null when not applicable.
     * @return True when the log is accepted or skipped for a null error; false only when persistence fails.
     */
    public static Boolean logDMLException(Database.Error error, String className, String methodName, String projectCode, String objectName, Id recordId) {
        if (error == null) {
            return true;
        }

        DES_Exceptions__b exc = createDMLException(error, className, methodName, projectCode, objectName, recordId, getNextTimestamp());
        return insertImmediate(new List<DES_Exceptions__b>{ exc });
    }

    /**
     * @description Logs Database.Error values produced by partial DML without a related record id.
     * @param errorList Database.Error values returned by partial DML operations.
     * @param className Class where the DML errors were captured.
     * @param methodName Method where the DML errors were captured.
     * @param projectCode Project code used to group the logs. Defaults to HVSC when blank.
     * @param objectName Related SObject API name, or blank when not applicable.
     * @return True when the list is accepted or empty; false only when persistence fails.
     */
    public static Boolean logDMLExceptionList(List<Database.Error> errorList, String className, String methodName, String projectCode, String objectName) {
        return logDMLExceptionList(errorList, className, methodName, projectCode, objectName, null);
    }

    /**
     * @description Logs Database.Error values produced by partial DML and optionally stores the related record id in each entry.
     * @param errorList Database.Error values returned by partial DML operations.
     * @param className Class where the DML errors were captured.
     * @param methodName Method where the DML errors were captured.
     * @param projectCode Project code used to group the logs. Defaults to HVSC when blank.
     * @param objectName Related SObject API name, or blank when not applicable.
     * @param recordId Related Salesforce record id, or null when not applicable.
     * @return True when the list is accepted or empty; false only when persistence fails.
     */
    public static Boolean logDMLExceptionList(List<Database.Error> errorList, String className, String methodName, String projectCode, String objectName, Id recordId) {
        List<DES_Exceptions__b> resultExceptionList = new List<DES_Exceptions__b>();
        if (errorList == null || errorList.isEmpty()) {
            return true;
        }

        for (Database.Error error : errorList) {
            if (error == null) {
                continue;
            }
            resultExceptionList.add(createDMLException(
                error,
                className,
                methodName,
                projectCode,
                objectName,
                recordId,
                getNextTimestamp()
            ));
        }
        return insertImmediate(resultExceptionList);
    }

    /**
     * @description Builds a DES_Exceptions__b entry from a Database.Error without persisting it.
     * @param error Database.Error returned by a partial DML operation.
     * @param className Class where the DML error was captured.
     * @param methodName Method where the DML error was captured.
     * @param projectCode Project code used to group the log. Defaults to HVSC when blank.
     * @param objectName Related SObject API name, or blank when not applicable.
     * @return Normalized DES_Exceptions__b entry, or null when the error is null.
     */
    public static DES_Exceptions__b logDMLExceptionWithoutInsert(Database.Error error, String className, String methodName, String projectCode, String objectName) {
        return logDMLExceptionWithoutInsert(error, className, methodName, projectCode, objectName, null);
    }

    /**
     * @description Builds a DES_Exceptions__b entry from a Database.Error without persisting it.
     * @param error Database.Error returned by a partial DML operation.
     * @param className Class where the DML error was captured.
     * @param methodName Method where the DML error was captured.
     * @param projectCode Project code used to group the log. Defaults to HVSC when blank.
     * @param objectName Related SObject API name, or blank when not applicable.
     * @param recordId Related Salesforce record id, or null when not applicable.
     * @return Normalized DES_Exceptions__b entry, or null when the error is null.
     */
    public static DES_Exceptions__b logDMLExceptionWithoutInsert(Database.Error error, String className, String methodName, String projectCode, String objectName, Id recordId) {
        if (error == null) {
            return null;
        }
        return createDMLException(error, className, methodName, projectCode, objectName, recordId, getNextTimestamp());
    }

    /**
     * @description Builds DES_Exceptions__b entries from Database.Error values without persisting them.
     * @param errorList Database.Error values returned by partial DML operations.
     * @param className Class where the DML errors were captured.
     * @param methodName Method where the DML errors were captured.
     * @param projectCode Project code used to group the logs. Defaults to HVSC when blank.
     * @param objectName Related SObject API name, or blank when not applicable.
     * @return Normalized DES_Exceptions__b entries. Empty when the input is null or empty.
     */
    public static List<DES_Exceptions__b> logDMLExceptionListWithoutInsert(List<Database.Error> errorList, String className, String methodName, String projectCode, String objectName) {
        return logDMLExceptionListWithoutInsert(errorList, className, methodName, projectCode, objectName, null);
    }

    /**
     * @description Builds DES_Exceptions__b entries from Database.Error values without persisting them.
     * @param errorList Database.Error values returned by partial DML operations.
     * @param className Class where the DML errors were captured.
     * @param methodName Method where the DML errors were captured.
     * @param projectCode Project code used to group the logs. Defaults to HVSC when blank.
     * @param objectName Related SObject API name, or blank when not applicable.
     * @param recordId Related Salesforce record id, or null when not applicable.
     * @return Normalized DES_Exceptions__b entries. Empty when the input is null or empty.
     */
    public static List<DES_Exceptions__b> logDMLExceptionListWithoutInsert(List<Database.Error> errorList, String className, String methodName, String projectCode, String objectName, Id recordId) {
        List<DES_Exceptions__b> resultExceptionList = new List<DES_Exceptions__b>();
        if (errorList == null || errorList.isEmpty()) {
            return resultExceptionList;
        }

        for (Database.Error error : errorList) {
            if (error == null) {
                continue;
            }
            resultExceptionList.add(createDMLException(
                error,
                className,
                methodName,
                projectCode,
                objectName,
                recordId,
                getNextTimestamp()
            ));
        }
        return resultExceptionList;
    }

    /**
    * @description Normalizes entries and persists them into DES_Exceptions__b.
    *              Trigger transactions are dispatched through ExceptionInsertQueueable to avoid mixed Big Object and sObject DML.
    *              Non-trigger transactions use Database.insertImmediate directly.
    *              In test context persistence is skipped unless forceInsertInTest is enabled.
     * @param exceptions Big Object entries to normalize and persist.
    * @return True when entries are accepted, empty, or skipped in tests; false when dispatch or insertImmediate fails.
     */
    private static Boolean insertImmediate(List<DES_Exceptions__b> exceptions) {
        List<DES_Exceptions__b> normalizedExceptions = normalizeExceptionEntries(exceptions);
        if (normalizedExceptions.isEmpty()) {
            return true;
        }

        if (Test.isRunningTest() && !forceInsertInTest) {
            return true;
        }

        if (Trigger.isExecuting) {
            return enqueueInsert(normalizedExceptions);
        }

        try {
            Database.insertImmediate(normalizedExceptions);
            return true;
        } catch (Exception e) {
            DES_Exception_Utils.logException(e, CLASSNAME, 'insertImmediate', DEFAULT_PROJECT_CODE, 'DES_Exceptions__b');
            return false;
        }
    }

    /**
     * @description Dispatches normalized entries to the queueable insert job used by trigger callers.
     * @param exceptions Normalized Big Object entries to persist after the trigger transaction.
     * @return True when the async request is accepted; false when dispatch fails.
     */
    private static Boolean enqueueInsert(List<DES_Exceptions__b> exceptions) {
        if (Limits.getQueueableJobs() >= Limits.getLimitQueueableJobs()) {
            return false;
        }

        try {
            System.enqueueJob(new ExceptionInsertQueueable(exceptions));
            return true;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to dispatch HVSC exception logs: ' + e.getMessage());
            return false;
        }
    }

    /**
     * @description Creates a normalized Big Object entry from a regular Apex exception.
     * @param e Exception captured by the caller.
     * @param className Class where the exception was captured.
     * @param methodName Method where the exception was captured.
     * @param projectCode Project code used to group the log.
     * @param objectName Related SObject API name, or blank when not applicable.
     * @param recordId Related Salesforce record id, or null when not applicable.
     * @param timestamp Timestamp assigned to the Big Object index field.
     * @return DES_Exceptions__b entry ready for normalization and persistence.
     */
    private static DES_Exceptions__b createRegularException(
        Exception e,
        String className,
        String methodName,
        String projectCode,
        String objectName,
        Id recordId,
        Datetime timestamp
    ) {
        DES_Exceptions__b exc = new DES_Exceptions__b();
        exc.Project__c = normalizeProjectCode(projectCode);
        exc.Class_Name__c = trimText(className);
        exc.Object__c = trimText(objectName);
        exc.Message__c = trimLongText(String.isBlank(e.getMessage()) ? e.getTypeName() : e.getMessage());
        exc.StackTrace__c = buildRegularStackTrace(e);
        exc.MethodName__c = trimText(methodName);
        exc.LineNumber__c = e.getLineNumber();
        exc.Type__c = DEFAULT_TYPE;
        exc.Timestamp__c = timestamp;
        exc.Reported_By__c = UserInfo.getUserId();
        exc.RecordId__c = recordId == null ? null : String.valueOf(recordId);
        return exc;
    }

    /**
     * @description Creates a normalized Big Object entry from a Database.Error produced by partial DML.
     * @param error Database.Error returned by a partial DML operation.
     * @param className Class where the DML error was captured.
     * @param methodName Method where the DML error was captured.
     * @param projectCode Project code used to group the log.
     * @param objectName Related SObject API name, or blank when not applicable.
     * @param recordId Related Salesforce record id, or null when not applicable.
     * @param timestamp Timestamp assigned to the Big Object index field.
     * @return DES_Exceptions__b entry ready for normalization and persistence.
     */
    private static DES_Exceptions__b createDMLException(
        Database.Error error,
        String className,
        String methodName,
        String projectCode,
        String objectName,
        Id recordId,
        Datetime timestamp
    ) {
        DES_Exceptions__b exc = new DES_Exceptions__b();
        exc.Project__c = normalizeProjectCode(projectCode);
        exc.Class_Name__c = trimText(className);
        exc.Object__c = trimText(objectName);
        exc.Message__c = trimLongText(error.getMessage());
        exc.StackTrace__c = buildDmlDetails(error);
        exc.DML_Fields__c = trimText(String.valueOf(error.getFields()));
        exc.MethodName__c = trimText(methodName);
        exc.Type__c = DEFAULT_TYPE;
        exc.Timestamp__c = timestamp;
        exc.Reported_By__c = UserInfo.getUserId();
        exc.RecordId__c = recordId == null ? null : String.valueOf(recordId);
        return exc;
    }

    /**
     * @description Applies required defaults, length limits, user attribution, and unique timestamps to prebuilt entries.
     * @param exceptions Entries received from callers or built by this utility.
     * @return Normalized entries safe to pass to Database.insertImmediate.
     */
    private static List<DES_Exceptions__b> normalizeExceptionEntries(List<DES_Exceptions__b> exceptions) {
        List<DES_Exceptions__b> normalizedExceptions = new List<DES_Exceptions__b>();
        if (exceptions == null || exceptions.isEmpty()) {
            return normalizedExceptions;
        }

        Set<Datetime> usedTimestamps = new Set<Datetime>();
        for (DES_Exceptions__b exceptionEntry : exceptions) {
            if (exceptionEntry == null) {
                continue;
            }

            if (exceptionEntry.Timestamp__c == null || usedTimestamps.contains(exceptionEntry.Timestamp__c)) {
                exceptionEntry.Timestamp__c = getNextTimestamp();
            }
            usedTimestamps.add(exceptionEntry.Timestamp__c);

            exceptionEntry.Project__c = normalizeProjectCode(exceptionEntry.Project__c);
            exceptionEntry.Class_Name__c = trimText(exceptionEntry.Class_Name__c);
            exceptionEntry.Object__c = trimText(exceptionEntry.Object__c);
            exceptionEntry.MethodName__c = trimText(exceptionEntry.MethodName__c);
            exceptionEntry.Type__c = String.isBlank(exceptionEntry.Type__c) ? DEFAULT_TYPE : trimText(exceptionEntry.Type__c);
            exceptionEntry.Message__c = trimLongText(exceptionEntry.Message__c);
            exceptionEntry.StackTrace__c = trimLongText(exceptionEntry.StackTrace__c);
            exceptionEntry.DML_Fields__c = trimText(exceptionEntry.DML_Fields__c);
            exceptionEntry.RecordId__c = trimRecordId(exceptionEntry.RecordId__c);
            exceptionEntry.Reported_By__c = exceptionEntry.Reported_By__c == null ? UserInfo.getUserId() : exceptionEntry.Reported_By__c;

            normalizedExceptions.add(exceptionEntry);
        }
        return normalizedExceptions;
    }

    /**
     * @description Builds the StackTrace__c payload for a regular Apex exception.
     * @param e Exception captured by the caller.
     * @return Exception type plus native Apex stack trace, trimmed to the Big Object field limit.
     */
    private static String buildRegularStackTrace(Exception e) {
        List<String> details = new List<String>{ 'ExceptionType=' + e.getTypeName() };
        if (!String.isBlank(e.getStackTraceString())) {
            details.add(e.getStackTraceString());
        }
        return trimLongText(String.join(details, '\n'));
    }

    /**
     * @description Builds the StackTrace__c payload for a Database.Error.
     * @param error Database.Error returned by a partial DML operation.
     * @return DML status code and field list, trimmed to the Big Object field limit.
     */
    private static String buildDmlDetails(Database.Error error) {
        List<String> details = new List<String>{
            'StatusCode=' + String.valueOf(error.getStatusCode()),
            'Fields=' + String.valueOf(error.getFields())
        };
        return trimLongText(String.join(details, '\n'));
    }

    /**
     * @description Returns a monotonic timestamp in the current transaction to reduce Big Object index collisions.
     * @return DateTime value that is greater than the previous generated timestamp in this transaction.
     */
    private static Datetime getNextTimestamp() {
        Long currentMillis = Datetime.now().getTime();
        if (lastTimestampMillis != null && currentMillis <= lastTimestampMillis) {
            currentMillis = lastTimestampMillis + 1;
        }
        lastTimestampMillis = currentMillis;
        return Datetime.newInstance(currentMillis);
    }

    /**
     * @description Applies the HVSC default project code when the caller does not provide one.
     * @param projectCode Project code received from the caller.
     * @return Trimmed project code or HVSC when blank.
     */
    private static String normalizeProjectCode(String projectCode) {
        return String.isBlank(projectCode) ? DEFAULT_PROJECT_CODE : trimText(projectCode);
    }

    /**
     * @description Normalizes a short text value for a Text(255) Big Object field.
     * @param value Value to normalize.
     * @return Non-null trimmed value limited to 255 characters.
     */
    private static String trimText(String value) {
        return trimToLength(String.isBlank(value) ? EMPTY_VALUE : value.trim(), TEXT_FIELD_MAX_LENGTH);
    }

    /**
     * @description Normalizes a record id string for RecordId__c.
     * @param value Record id value to normalize.
     * @return Trimmed value limited to 18 characters, or null when blank.
     */
    private static String trimRecordId(String value) {
        return trimToLength(String.isBlank(value) ? null : value.trim(), 18);
    }

    /**
     * @description Normalizes a long text value for LongTextArea Big Object fields.
     * @param value Value to normalize.
     * @return Non-null value limited to 32768 characters.
     */
    private static String trimLongText(String value) {
        return trimToLength(String.isBlank(value) ? EMPTY_VALUE : value, LONG_TEXT_FIELD_MAX_LENGTH);
    }

    /**
     * @description Trims a value to the provided maximum length.
     * @param value Value to trim.
     * @param maxLength Maximum allowed length.
     * @return Original value when within the limit, or a substring limited to maxLength.
     */
    private static String trimToLength(String value, Integer maxLength) {
        if (value == null || value.length() <= maxLength) {
            return value;
        }
        return value.substring(0, maxLength);
    }
}