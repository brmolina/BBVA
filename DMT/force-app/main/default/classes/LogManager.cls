public with sharing class LogManager {

    // --- 1. SETUP & TRACING ---
    @AuraEnabled
    public static void setTraceFlag(Boolean enable) {
        Id userId = UserInfo.getUserId();
        Map<String, Object> q = toolingQuery('SELECT Id FROM TraceFlag WHERE TracedEntityId = \'' + userId + '\'');
        if (q != null && q.containsKey('records')) {
            for (Object obj : (List<Object>) q.get('records')) {
                toolingRequest('DELETE', '/sobjects/TraceFlag/' + ((Map<String, Object>)obj).get('Id'), null);
            }
        }

        if (enable) {
            String debugLevelId = getOrCreateDebugLevelId();
            if (debugLevelId != null) {
                Map<String, Object> traceFlag = new Map<String, Object>();
                traceFlag.put('DebugLevelId', debugLevelId);
                traceFlag.put('StartDate', System.now());
                traceFlag.put('ExpirationDate', System.now().addMinutes(30));
                traceFlag.put('LogType', 'USER_DEBUG');
                traceFlag.put('TracedEntityId', userId);
                toolingRequest('POST', '/sobjects/TraceFlag/', traceFlag);
            }
        }
    }

    // --- 2. STEP 1: FETCH RAW METADATA ---
    @AuraEnabled
    public static String fetchLogs(String afterTimestamp) {
        DateTime dt = String.isNotBlank(afterTimestamp) ? 
                      (DateTime)JSON.deserialize('"' + afterTimestamp + '"', DateTime.class) : 
                      System.now().addMinutes(-10);
        String isoTime = dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');

        String query = 'SELECT Id, Status, Operation, DurationMilliseconds, LogLength, LastModifiedDate FROM ApexLog ' + 
                       'WHERE LogUser.Id = \'' + UserInfo.getUserId() + '\' ' + 
                       'AND LastModifiedDate > ' + isoTime + ' ' + 
                       'ORDER BY LastModifiedDate DESC LIMIT 50';

        Map<String, Object> result = toolingQuery(query);
        List<Object> rawLogs = (result != null && result.containsKey('records')) ? (List<Object>) result.get('records') : new List<Object>();
        
        return JSON.serialize(rawLogs);
    }

    // --- 3. STEP 2: INSPECT & EXTRACT SIGNATURE (Race Condition Fix) ---
    @AuraEnabled
    public static Map<String, String> identifyLogSignatures(List<String> logIds) {
        Map<String, String> results = new Map<String, String>();
        
        Set<String> NOISE_SIGS = new Set<String>{
            'LogManager', 'AsyncLogDeleter', 'fetchLogs', 'toolingRequest', '/services/data', 'QueueableContext'
        };

        for (String logId : logIds) {
            String body = rawToolingRequest('GET', '/sobjects/ApexLog/' + logId + '/Body', null);
            
            // --- FIX START: Handle "Already Deleted" Logs ---
            // If another tab deleted the log while we were processing, Salesforce returns this error.
            // We treat it as "NOISE" so it gets removed from the UI cleanly.
            if (body.contains('INVALID_CROSS_REFERENCE_KEY') || body.contains('NOT_FOUND')) {
                results.put(logId, 'NOISE');
                continue; 
            }
            // --- FIX END ---

            Boolean isNoise = false;
            for (String sig : NOISE_SIGS) {
                if (body.contains(sig)) {
                    results.put(logId, 'NOISE');
                    isNoise = true;
                    break;
                }
            }
            if (isNoise) continue;

            String signature = 'Anonymous / System'; 
            Matcher m = Pattern.compile('.*\\|(CODE_UNIT_STARTED|METHOD_ENTRY)\\|.*\\|([a-zA-Z0-9_]+\\.[a-zA-Z0-9_]+).*').matcher(body);
            if (m.find()) {
                signature = m.group(2);
            }
            results.put(logId, signature);
        }
        return results;
    }

    // --- 4. STEP 3: DELETE LOGS (Quietly) ---
    @AuraEnabled
    public static void deleteLogs(List<String> logIds) {
        if (logIds == null || logIds.isEmpty()) return;
        System.enqueueJob(new AsyncLogDeleter(JSON.serialize(logIds)));
    }

    public class AsyncLogDeleter implements Queueable, Database.AllowsCallouts {
        private String serializedIds;
        public AsyncLogDeleter(String serializedIds) { this.serializedIds = serializedIds; }
        public void execute(QueueableContext context) {
            List<String> allIds = (List<String>) JSON.deserialize(serializedIds, List<String>.class);
            List<String> remaining = new List<String>(allIds);
            Integer count = 0;
            while(count < 90 && !remaining.isEmpty()) {
                // If this fails (e.g. already deleted), we don't care. It's fire-and-forget.
                toolingRequest('DELETE', '/sobjects/ApexLog/' + remaining.remove(0), null);
                count++;
            }
            if(!remaining.isEmpty() && !Test.isRunningTest()) System.enqueueJob(new AsyncLogDeleter(JSON.serialize(remaining)));
        }
    }

    // --- 5. HELPERS ---
    @AuraEnabled
    public static String getLogBody(String logId) {
        String body = rawToolingRequest('GET', '/sobjects/ApexLog/' + logId + '/Body', null);
        // Clean return if missing
        if (body.contains('INVALID_CROSS_REFERENCE_KEY')) return null;
        return body;
    }
    
    @AuraEnabled
    public static Boolean checkActiveTraceFlag() {
        Map<String, Object> r = toolingQuery('SELECT Id FROM TraceFlag WHERE TracedEntityId = \'' + UserInfo.getUserId() + '\'');
        return (r != null && r.containsKey('records') && !((List<Object>)r.get('records')).isEmpty());
    }

    private static String rawToolingRequest(String method, String path, String body) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Self_Loopback_NC/services/data/v60.0/tooling' + path);
        req.setMethod(method);
        req.setHeader('Content-Type', 'application/json');
        if (body != null) req.setBody(body);
        try {
            HttpResponse res = new Http().send(req);
            return res.getBody();
        } catch(Exception e) { return ''; }
    }

    private static Map<String, Object> toolingRequest(String method, String path, Map<String, Object> body) {
        try { return (Map<String, Object>) JSON.deserializeUntyped(rawToolingRequest(method, path, body!=null?JSON.serialize(body):null)); } 
        catch (Exception e) { return new Map<String, Object>(); }
    }

    private static Map<String, Object> toolingQuery(String q) {
        return toolingRequest('GET', '/query/?q=' + EncodingUtil.urlEncode(q, 'UTF-8'), null);
    }

    private static String getOrCreateDebugLevelId() {
        Map<String, Object> r = toolingQuery('SELECT Id FROM DebugLevel WHERE DeveloperName = \'LWC_Stream_Level\'');
        if (r != null && r.containsKey('records') && !((List<Object>)r.get('records')).isEmpty()) 
            return (String) ((Map<String, Object>)((List<Object>)r.get('records'))[0]).get('Id');
        Map<String, Object> lvl = new Map<String, Object>{
            'DeveloperName' => 'LWC_Stream_Level', 'MasterLabel' => 'LWC Stream Level', 'ApexCode' => 'FINEST', 'ApexProfiling' => 'INFO'
        };
        return (String) toolingRequest('POST', '/sobjects/DebugLevel/', lvl).get('id');
    }
}