public with sharing class DMT_AsyncDispatcher {

    public static void dispatch(DMT_AsyncPayload payload) {
        if (payload instanceof DMT_SnapshotPayload) {
            handleSnapshotLineVersion((DMT_SnapshotPayload) payload);
        } else if (payload instanceof DMT_LogExceptionPayload) {
            handleLogException((DMT_LogExceptionPayload) payload);
        } else if (payload instanceof DMT_LogApplicationPayload) {
            handleApplicationLogRecords((DMT_LogApplicationPayload) payload);
        } else if (payload instanceof DMT_PassportPayload) {
            DMT_Passport_Handler.handlePassportIntegration((DMT_PassportPayload) payload);
        } else if (payload instanceof DES_ProspectStructurePayload) {
            DES_ProspectStructureBuilder.handleProspectIntegration((DES_ProspectStructurePayload) payload);
        } else if (payload instanceof DMT_IntegrationRetryPayload) {
            DMT_IntegrationRetryPayload p = (DMT_IntegrationRetryPayload) payload;
            // Instantiates the processor and runs it synchronously within the current async thread
            DMT_IntegrationEventProcessor processor = new DMT_IntegrationEventProcessor(p.objectApi, p.operation, p.version, p.seed, p.failedIds, p.attempt);
            processor.executeProcessor();
        } else if (payload instanceof DMT_ConsumptionReassignPayload) {
            handleConsumptionReassign((DMT_ConsumptionReassignPayload) payload);
        } else if (payload instanceof DMT_OppXSellPayload) {
            DMT_Opportunity_Utils.handleOppXSellGeneration((DMT_OppXSellPayload) payload);
        } else if (payload instanceof DMT_DynamicMapperPayload) {
            DMT_PAWIF_IntegrationHandler.handleClosingIntegration((DMT_DynamicMapperPayload) payload);
        } else if (payload instanceof DMT_CoreDocumentsUploadPayload) {
            DMT_CoreDocumentsUploadPayload p = (DMT_CoreDocumentsUploadPayload) payload;
            DMT_CoreDocumentsUploadFile.upload(p.sfRecordId, p.fileBaseName, p.pdfBase64);
        } else if (payload instanceof DMT_RestartApprovalTasksPayload) {
            DMT_RestartApprovalTasksPayload p = (DMT_RestartApprovalTasksPayload) payload;
            DMT_ApprovalChangeStep_Helper.restartTasksForRecord(p.recordId, p.tasksToRestart);
        } else if (payload instanceof DMT_DocumentTransferPayload) {
            DMT_DocumentTransferPayload p = (DMT_DocumentTransferPayload) payload;
            DMT_DocumentTransferService.transferDocuments(p.taskIdByCaseId);
        } else if (payload instanceof DMT_WutSurveyPayload) {
            handleWutSurveyPublish((DMT_WutSurveyPayload) payload);
        } else if (payload instanceof DMT_CalloutTrackableCheckPayload) {
            DMT_ApprovalChangeStep_Helper.checkCalloutTrackableComponent((DMT_CalloutTrackableCheckPayload) payload);
        } else if (payload instanceof DMT_StartApprovalCasePayload) {
            DMT_Case_Steps_Controller.startApprovalCaseFromPayload((DMT_StartApprovalCasePayload) payload);
        } else if (payload instanceof DMT_CalloutTrackableFreezePayload) {
            DMT_ApprovalChangeStep_Helper.freezeCalloutTrackableBaseline((DMT_CalloutTrackableFreezePayload) payload);
        } else {
            throw new IllegalArgumentException('Unsupported payload type');
        }
    }

    public static void handleLogExceptions(List<DMT_AsyncPayload> payloads) {
        if (payloads == null || payloads.isEmpty()) {
            return;
        }

        // 1. Create a new list of the target type
        List<DMT_LogExceptionPayload> errorPayloads = new List<DMT_LogExceptionPayload>();

        // 2. Loop and cast each item individually
        for (DMT_AsyncPayload p : payloads) {
            if (p instanceof DMT_LogExceptionPayload) {
                errorPayloads.add((DMT_LogExceptionPayload)p);
            }
        }
        try {
            if (System.isQueueable() || System.isBatch() || System.isScheduled() || System.isFuture()) {
                List<DES_Exceptions__b> excList = new List<DES_Exceptions__b>();
                for(DMT_LogExceptionPayload pl : errorPayloads) {
                // CIRCUIT BREAKER: If this is an error about an error, just debug it and stop.
                if (pl.className == 'DMT_LogExceptionQueueable') {
                    System.debug(LoggingLevel.ERROR, ' [DMT] TERMINAL ERROR: Failed to log an existing error. Stopping to prevent infinite loop. Original Message: ' + pl.message);
                        continue;
                    }

                    DES_Exceptions__b exc = new DES_Exceptions__b();
                    exc.Project__c = pl.projectCode;
                    exc.Class_Name__c = pl.className;
                    exc.Object__c = pl.objectName;
                    exc.Message__c = pl.message;
                    exc.StackTrace__c = pl.stackTrace;
                    exc.MethodName__c = pl.methodName;
                    exc.LineNumber__c = pl.lineNumber;
                    exc.Type__c = pl.typeName;
                    exc.Timestamp__c = DateTime.now();
                    exc.Reported_By__c = UserInfo.getUserId();
                    excList.add(exc);
                }

                if (!excList.isEmpty()) {
                    if (!Test.isRunningTest()) {
                    Database.insertImmediate(excList);
                    } else {
                        System.debug('Test context: skipping insertImmediate to avoid Uncommitted Work error');
                    }
                }
            } else {
                System.enqueueJob(new DMT_LogExceptionQueueable(errorPayloads));
            }
        } catch (Exception e) {
            // THE DEAD END: If logging fails, we just print to console.
            // Do NOT let this exception bubble up to the Batch/Queueable.
            System.debug(LoggingLevel.ERROR, ' [DMT] CRITICAL FAILURE: Could not write to Big Object: ' + e.getMessage());
        }
    }

    // CIBGLOBALD-4295 - Captures WUT survey Platform Events published in test context, for assertion -
    // the Queueable that carries this dispatch executes at Test.stopTest(), so tests read this after
    // that call.
    @TestVisible private static List<DES_pe_SurveyNotification__e> publishedWutSurveyEvents = new List<DES_pe_SurveyNotification__e>();

    private static void handleWutSurveyPublish(DMT_WutSurveyPayload payload) {
        DES_pe_SurveyNotification__e evt = DES_cls_BotonNoteBookLm.buildSurveyEvent(
            payload.survey, payload.moduleName, payload.userIds
        );
        if (Test.isRunningTest()) {
            publishedWutSurveyEvents.add(evt);
        }
        EventBus.publish(evt);
    }

    private static void handleSnapshotLineVersion(DMT_SnapshotPayload payload) {
        String requestStr = JSON.serialize(payload.request);
        String response = DMT_SnapshotEvaluationVersions.processPostSnapshotEvaluationVersion(requestStr, payload.recordId, payload.type);
        System.debug('Response from Snapshot Eval API: ' + response);
    }

    private static void handleLogException(DMT_LogExceptionPayload pl) {
        if (System.isQueueable() || System.isBatch() || System.isScheduled() || System.isFuture()) {
            DES_Exceptions__b exc = new DES_Exceptions__b();
            exc.Project__c = pl.projectCode;
            exc.Class_Name__c = pl.className;
            exc.Object__c = pl.objectName;
            exc.Message__c = pl.message;
            exc.StackTrace__c = pl.stackTrace;
            exc.MethodName__c = pl.methodName;
            exc.LineNumber__c = pl.lineNumber;
            exc.Type__c = pl.typeName;
            exc.Timestamp__c = DateTime.now();
            exc.Reported_By__c = UserInfo.getUserId();

            if (!Test.isRunningTest()) {
                Database.insertImmediate(new List<DES_Exceptions__b>{exc});
            } else {
                System.debug('Test context: skipping insertImmediate to avoid Uncommitted Work error');
            }

        } else {
            System.enqueueJob(new DMT_LogExceptionQueueable(
                pl.message, pl.stackTrace, pl.lineNumber, pl.typeName,
                pl.className, pl.methodName, pl.projectCode, pl.objectName
            ));
        }
    }

    private static void handleApplicationLogRecords(DMT_LogApplicationPayload payload) {
        final String uuid = getUuid();
        List<iaso__GBL_Application_Log__c> logListToInsert = new List<iaso__GBL_Application_Log__c>();
        for (iaso__GBL_Application_Log__c tmp : payload.logs) {
            tmp.iaso__Elapsed_Time__c = tmp.iaso__End_Time__c.getTime() - tmp.iaso__Start_Time__c.getTime();
            if (tmp.iaso__Message_LTA__c.length() > 131000) {
                tmp.iaso__Message_LTA__c = tmp.iaso__Message_LTA__c.substring(0, 131000) + ' ... (' + (tmp.iaso__Message_LTA__c.length() - 131000).format() + ' chars more)';
            }
            tmp.iaso__Transaction_Id__c = uuid;
            tmp.Name = tmp.Name.left(80);
            tmp.iaso__Type__c = 'Integration';
            tmp.OwnerId = UserInfo.getUserId();
            tmp.iaso__User__c = UserInfo.getUserId();
            logListToInsert.add(tmp);
        }
        if (!logListToInsert.isEmpty()) {
            insert logListToInsert;
        }
    }

    private static String getUuid() {
        String s = Datetime.now().getTime().format();
        Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(s));
        return EncodingUtil.convertToHex(hash);
    }

    // Lets tests simulate a non-204 response without a real HttpCalloutMock for this method.
    // Mirrors DMT_IntegrationEventProcessor's forceFailForTest/forceExceptionForTest convention.
    @TestVisible private static Integer forceStatusCodeForTest = null;

    // Any failure here must propagate (not be swallowed): this method always runs after an
    // HTTP callout, and Big Object writes (Database.insertImmediate, used to persist
    // DES_Exceptions__b) aren't allowed in the same transaction as a callout. The callers
    // of DMT_AsyncDispatcher.dispatch() - DMT_AsyncQueueJob.execute() / DMT_AsyncBatchJob.execute() -
    // already catch exceptions from dispatch() and defer the actual log write to a fresh,
    // callout-free transaction (a new Batch/Queueable), exactly like every other payload
    // type in this dispatcher.
    public static void handleConsumptionReassign(DMT_ConsumptionReassignPayload p) {
        // 1. Build the inner business payload directly from the input map
        Map<String, Object> payload = new Map<String, Object>();

        Map<String, Object> clientMap = new Map<String, Object>();
        clientMap.put('groupId', (String) p.inputMap.get('groupId'));
        payload.put('client', clientMap);

        if (p.inputMap.containsKey('opportunityId')) {
            payload.put('opportunityId', (String) p.inputMap.get('opportunityId'));
        }

        // 2. Build the outer integration framework request wrapper
        Map<String, Object> request = new Map<String, Object>();
        request.put('jsonInput', JSON.serialize(payload));

        // 3. INJECT THE USER ID MANUALLY
        if (String.isNotBlank(p.corporateUserId)) {
            request.put('userId', p.corporateUserId);
        } else {
            request.put('userId', 'SystemAsync');
        }

        String requestStr = JSON.serialize(request);
        String serviceName = 'DMT_consumptionsReassign';

        System.debug('>>> Orchestrator: Executing handleConsumptionReassign: ' + requestStr);

        // 4. Invoke IASO directly
        HttpResponse response;
        if (Test.isRunningTest()) {
            response = new HttpResponse();
            response.setStatusCode(forceStatusCodeForTest != null ? forceStatusCodeForTest : 204);
        } else {
            response = iaso.GBL_Integration_GenericService.invoke(serviceName, requestStr);
            if (UserInfo.getUserId() == '005KE0000014hDgYAI' || UserInfo.getUserId() == '00557000006ApHLAA0') {
                DebugMessenger.sendIntegrationInvocation(
                    serviceName,
                    requestStr,
                    'DMT_AsyncDispatcher.handleConsumptionReassign(p); ' + serviceName + ' REQUEST'
                );

                DebugMessenger.sendIntegrationInvocation(
                    serviceName,
                    response.getBody(),
                    'DMT_AsyncDispatcher.handleConsumptionReassign(p); ' + serviceName + ' RESPONSE'
                );
            }
        }

        // 5. Evaluate response
        if (response != null && response.getStatusCode() == 204) {
            System.debug('>>> SUCCESS: Orchestrated handleConsumptionReassign completed (204 No Content).');
            return;
        }
        System.debug('>>> FAIL: Orchestrated handleConsumptionReassign failed with HTTP ' + (response != null ? response.getStatusCode() : null) + '.');

        Integer statusCode = response != null ? response.getStatusCode() : null;
        String body = response != null ? response.getBody() : null;
        throw new CalloutException('Recalculate Approvals callout failed with HTTP ' + statusCode + (String.isNotBlank(body) ? ': ' + body : ''));
    }
}