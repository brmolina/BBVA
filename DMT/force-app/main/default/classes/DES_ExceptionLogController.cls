/**
 * @description Apex controller exposed to LWC components for server-side error logging.
 *              Receives exception data captured in JavaScript and persists it via
 *              HVSC_Exception_Utils into the DES_Exceptions__b big object.
 *              Supports single and batch logging through a typed wrapper class.
 * @author Borja Lorenzo Adajas
 * @date 2026-06-17
 */
public with sharing class DES_ExceptionLogController {

    private static final String CLASSNAME = 'DES_ExceptionLogController';
    private static final String DEFAULT_PROJECT_CODE = 'HVSC';
    private static final String DEFAULT_TYPE = 'LWC';

    // ──────────────────────────────────────────────────────────────────────────
    // Inner Wrapper
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * @description Data transfer object carrying LWC error details.
     *              Populated via JSON.deserialize from the errorsJson parameter.
     */
    public class ExceptionInput {
        public String componentName;
        public String methodName;
        public String projectCode;
        public String objectName;
        public String recordId;
        public String message;
        public String stackTrace;
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Public AuraEnabled Methods
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * @description Logs one or more LWC exceptions captured in JavaScript.
     *              Accepts a JSON-serialized array of ExceptionInput objects.
     *              Using a String parameter avoids the known Salesforce inner-class
     *              deserialization issue when List<InnerClass> is passed from LWC.
     * @param errorsJson  JSON string representing a List<ExceptionInput>.
     */
    @AuraEnabled
    public static void logExceptions(String errorsJson) {
        try {
            if (String.isBlank(errorsJson)) {
                return;
            }
            final List<ExceptionInput> errors = (List<ExceptionInput>) JSON.deserialize(
                errorsJson, List<ExceptionInput>.class
            );
            final List<DES_Exceptions__b> entries = new List<DES_Exceptions__b>();
            // Base timestamp in milliseconds. Each entry gets +1 ms offset so that
            // batch inserts never collide on the Timestamp__c unique index of DES_Exceptions__b.
            final Long baseMillis = Datetime.now().getTime();
            Integer offset = 0;
            for (ExceptionInput input : errors) {
                if (String.isBlank(input.message)) {
                    continue;
                }
                final Datetime entryTimestamp = Datetime.newInstance(baseMillis + offset);
                offset++;
                entries.add(buildEntry(
                    input.componentName,
                    input.methodName,
                    input.projectCode,
                    input.objectName,
                    input.recordId,
                    input.message,
                    input.stackTrace,
                    entryTimestamp
                ));
            }
            if (!entries.isEmpty()) {
                HVSC_Exception_Utils.logDesExceptionsList(entries);
            }
        } catch (Exception e) {
            // Log internally but do not re-throw: logExceptions is fire-and-forget
            // from the LWC side; propagating an exception here would surface an
            // unhandled error in the caller's .catch, not another log entry.
            HVSC_Exception_Utils.logException(e, CLASSNAME, 'logExceptions', DEFAULT_PROJECT_CODE, '');
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Private Helpers
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * @description Builds a DES_Exceptions__b record from raw string fields
     *              provided by an LWC component.
     */
    private static DES_Exceptions__b buildEntry(
        String componentName,
        String methodName,
        String projectCode,
        String objectName,
        String recordId,
        String message,
        String stackTrace,
        Datetime timestamp
    ) {
        final DES_Exceptions__b entry = new DES_Exceptions__b();
        entry.Project__c      = String.isBlank(projectCode)    ? DEFAULT_PROJECT_CODE : projectCode;
        entry.Class_Name__c   = String.isBlank(componentName)  ? ''     : componentName;
        entry.MethodName__c   = String.isBlank(methodName)     ? ''     : methodName;
        entry.Object__c       = String.isBlank(objectName)     ? ''     : objectName;
        entry.RecordId__c     = String.isBlank(recordId)       ? null   : recordId;
        entry.Message__c      = message;
        entry.StackTrace__c   = String.isBlank(stackTrace)     ? ''     : stackTrace;
        entry.Type__c         = DEFAULT_TYPE;
        entry.Timestamp__c    = timestamp;
        entry.Reported_By__c  = UserInfo.getUserId();
        return entry;
    }
}