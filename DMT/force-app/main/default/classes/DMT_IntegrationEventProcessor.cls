/**-------------------------------------------------------------------------------------------
* @Name     DMT_IntegrationEventProcessor
* @Author   Javier Portilla <javieralberto.portilla.contractor@bbva.com>
* @Date     Created: 2025-09-02
* --------------------------------------------------------------------------------------------
* @Description Processes events published by DMT_Integration_Event__e, managing payload construction, callout execution, and retry mechanisms.
* --------------------------------------------------------------------------------------------
*/
public with sharing class DMT_IntegrationEventProcessor implements Queueable, Database.AllowsCallouts {

 private static final Integer MAX_ATTEMPTS = 6;

    private final String objectApi;
    private final String operation;
    private final String version;
    private final String seed;
    private final List<Id> recordIds;
    private final Integer attempt;

    // Test Hooks to cover exception and failure paths
    @TestVisible private static Boolean forceFailForTest = false;
    @TestVisible private static Boolean forceExceptionForTest = false;

    public DMT_IntegrationEventProcessor(String objectApi, String operation, String version, String seed, List<Id> recordIds, Integer attempt){
        this.objectApi = objectApi;
        this.version   = String.isBlank(version) ? 'v1' : version;
        this.seed      = String.isBlank(seed) ? String.valueOf(System.currentTimeMillis()) : seed;
        this.recordIds = (recordIds == null) ? new List<Id>() : recordIds.clone();
        this.attempt   = (attempt == null) ? 0 : attempt;
    }

    /**
     * Aggregates jobs from the Platform Event trigger.
     * Normalizes all incoming records to DMT_Line__c, deduplicates them, 
     * and partitions them to respect the 100 HTTP callout limit per transaction.
     */
    public static void enqueueFromEvents(List<DMT_Integration_Event__e> events) {
        if (events == null || events.isEmpty()) return;

        // 1. Collect all IDs grouped by their incoming Object type
        Map<String, Set<Id>> idsByObject = new Map<String, Set<Id>>();
        String payloadVersion = 'v1';
        String seed = String.valueOf(System.currentTimeMillis());

        for (DMT_Integration_Event__e evt : events) {
            if (String.isBlank(evt.Object__c) || String.isBlank(evt.RecordIds__c)) continue;
            
            if (!idsByObject.containsKey(evt.Object__c)) {
                idsByObject.put(evt.Object__c, new Set<Id>());
            }
            
            for (String s : evt.RecordIds__c.split(',')) { 
                if (String.isNotBlank(s)) {
                    idsByObject.get(evt.Object__c).add((Id)s.trim()); 
                }
            }
            
            // Capture version/seed from the event stream
            if (String.isNotBlank(evt.PayloadVersion__c)) payloadVersion = evt.PayloadVersion__c;
            if (String.isNotBlank(evt.Seed__c)) seed = evt.Seed__c;
        }

        // 2. NORMALIZATION GUARDRAIL: Resolve everything to DMT_Line__c
        Set<Id> masterLineIds = new Set<Id>();
        
        for (String objName : idsByObject.keySet()) {
            Set<Id> sourceIds = idsByObject.get(objName);
            
            if (objName == 'DMT_Line__c') {
                masterLineIds.addAll(sourceIds);
            } else {
                // Safe, bulkified resolution using helper
                List<Id> resolvedIds = DMT_RiskPositionLine_Helper.getLineIds(objName, sourceIds);
                masterLineIds.addAll(resolvedIds);
            }
        }

        if (masterLineIds.isEmpty()) return;

        // 3. CHUNKING GUARDRAIL: What if we have > 100 IDs?
        // We must split the deduplicated master set into chunks of 80 to protect the Queueable
        List<Id> allLineIdsList = new List<Id>(masterLineIds);
        Integer maxSafeCallouts = 80; 
        List<List<Id>> safeChunks = new List<List<Id>>();
        List<Id> currentChunk = new List<Id>();
        
        for (Id lineId : allLineIdsList) {
            currentChunk.add(lineId);
            if (currentChunk.size() == maxSafeCallouts) {
                safeChunks.add(currentChunk);
                currentChunk = new List<Id>();
            }
        }
        if (!currentChunk.isEmpty()) {
            safeChunks.add(currentChunk);
        }

        // 4. Enqueue the safely chunked jobs
        // Note: Forced Object to 'DMT_Line__c' and Operation to 'Update'
        for (List<Id> chunkToProcess : safeChunks) {
            System.enqueueJob(new DMT_IntegrationEventProcessor(
                'DMT_Line__c',       
                'Update',            
                payloadVersion,      
                seed,                
                chunkToProcess,      
                0
            ));
        }
    }

    // Standard Queueable entry point (used by the Platform Event Trigger)
    public void execute(QueueableContext qc) {
        executeProcessor();
        // Finalize transaction only if invoked independently 
        DMT_AsyncOrchestrator.flush();
    }

    // Direct execution method (used by the Async Orchestrator)
    public void executeProcessor() {
        System.debug('>>> Starting execution process. Total records: ' + recordIds.size());
        if (recordIds.isEmpty()) return;

        // Mark as inbound to prevent trigger recursion
        DMT_IntegrationContext.setInbound(true);
        List<Id> failed = new List<Id>();

        try {
            // BULK: Get context wrappers (contains both SObject data and JSON payloads)
            Map<Id, DMT_RiskPositionLine_Helper.LinePayloadContext> contexts = DMT_RiskPositionLine_Helper.buildPayloadsBulk(recordIds, version);
            System.debug('>>> Bulk Contexts retrieved successfully. Count: ' + contexts.size());

            for (Id recId : recordIds) {
                System.debug('>>> --- Processing Record ID: ' + recId + ' ---');
                try {
                    DMT_RiskPositionLine_Helper.LinePayloadContext ctx = contexts.get(recId);
                    
                    // Skip if nothing to process
                    if (ctx == null || ctx.payloads.isEmpty()) {
                        System.debug('>>> SKIP: Context is null or payloads are empty for ID: ' + recId);
                        continue;
                    }

                    // --- 1. FIRST CALLOUT ---
                    System.debug('>>> Executing FIRST Callout. Number of payloads: ' + ctx.payloads.size());
                    Map<String, Object> res = DMT_RiskPositionLine_Helper.send(ctx.payloads);
                    Integer http = (Integer) res.get('statusCode');
                    Boolean ok   = (Boolean) res.get('result');
                    
                    // Inject test failures to cover red lines
                    if (Test.isRunningTest() && forceFailForTest) ok = false;
                    if (Test.isRunningTest() && forceExceptionForTest) throw new CalloutException('Simulated exception for test coverage');

                    System.debug('>>> FIRST Callout Response -> HTTP: ' + http + ' | Result OK: ' + ok);
                    System.debug('>>> FIRST Callout Full Detail: ' + JSON.serialize(res));

                    if (ok == true && http != null && http >= 200 && http < 300) {
                        
                        // --- 2. SECOND CALLOUT (Chained execution) ---
                        DMT_Line__c ln = ctx.lineRecord;
                        
                        System.debug('>>> Evaluating criteria for SECOND callout. Line_Id__c: ' + ln.Line_Id__c);
                        System.debug('>>> Criteria 1 -> Template Type: ' + ln.DMT_line_template_type__c);
                        System.debug('>>> Criteria 2 -> Status Completed: ' + ln.DMT_Status_Completed__c);
                        
                        // Check criteria using the pre-queried SObject fields
                        if (ln.RecordType.DeveloperName == 'Sanction' && ln.DMT_line_template_type__c == 'OP' && 
                           (ln.DMT_Status_Completed__c == 'Ready to close' || ln.DMT_Status_Completed__c == 'Closed Won')) {
                            
                            System.debug('>>> SECOND Callout criteria MET. Preparing request...');
                            Map<String, Object> inputMap = new Map<String, Object>();
                            
                            // Determine groupId
                            String groupId = (ln.Client_Type__c == 'Customer') 
                                ? ln.Client__r?.DES_Main_Parent__r?.DES_Group_Code__c 
                                : ln.Client__r?.DES_group_Code__c;
                                
                            // --- VALIDATION GUARDRAIL ---
                            if (String.isBlank(groupId)) {
                                throw new CalloutException('Missing Group ID: Cannot proceed with second callout (consumptionsReassign).');
                            }
                            
                            inputMap.put('groupId', groupId);
                            
                            // Append opportunityId if Ready to close
                            if (ln.DMT_Status_Completed__c == 'Ready to close') {
                                inputMap.put('opportunityId', ln.Line_Id__c);
                            }
                            
                            System.debug('>>> SECOND Callout InputMap Payload: ' + JSON.serialize(inputMap));
                            
                            // Enqueue the payload to the Orchestrator to avoid uncommitted work pending DML errors
                            DMT_AsyncOrchestrator.enqueue(new DMT_ConsumptionReassignPayload(inputMap, ln.DMT_ID_User__c));
                            
                            System.debug('>>> SUCCESS: Second callout safely enqueued to the Orchestrator.');
                        } else {
                            System.debug('>>> SKIP SECOND CALLOUT: Criteria NOT met.');
                        }

                    } else {
                        // First callout failed
                        System.debug('>>> FAILED FIRST CALLOUT. Adding record to failed list for re-enqueue.');
                        failed.add(recId);
                    }

                } catch (Exception innerException) {
                    System.debug('>>> EXCEPTION inside loop for ID ' + recId + ': ' + innerException.getMessage());
                    System.debug('>>> StackTrace: ' + innerException.getStackTraceString());
                    
                    failed.add(recId);
                    DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(
                        innerException.getMessage(), 
                        innerException.getStackTraceString(), 
                        innerException.getLineNumber(), 
                        innerException.getTypeName(),
                        'DMT_IntegrationEventProcessor',
                        'execute',
                        'DMT',
                        ''
                    ));
                }
            }
        } finally {
            DMT_IntegrationContext.setInbound(false);
        }

        // Buffer failures for Re-enqueueing via Orchestrator
        if (!failed.isEmpty() && attempt + 1 < MAX_ATTEMPTS) {
            System.debug('>>> Re-enqueueing ' + failed.size() + ' failed records via Orchestrator. Next attempt: ' + (attempt + 1));
            DMT_AsyncOrchestrator.enqueue(new DMT_IntegrationRetryPayload(objectApi, operation, version, seed, failed, attempt + 1));
        } else if (!failed.isEmpty()) {
            System.debug('>>> MAX ATTEMPTS REACHED. ' + failed.size() + ' records permanently failed.');
        }
        // REMOVED FLUSH: The Orchestrator will handle its own flushing from now on.
    }

    // Legacy enqueue method for singular event records
    public static void enqueueFromEvent(DMT_Integration_Event__e evt){
        if (evt == null || String.isBlank(evt.Object__c) || String.isBlank(evt.RecordIds__c)) return;
        List<Id> ids = new List<Id>();
        for (String s : evt.RecordIds__c.split(',')) { if (String.isNotBlank(s)) ids.add((Id)s.trim()); }
        if (!ids.isEmpty()){
            System.enqueueJob(new DMT_IntegrationEventProcessor(evt.Object__c, evt.Operation__c, evt.PayloadVersion__c, evt.Seed__c, ids, 0));
        }
    }
}