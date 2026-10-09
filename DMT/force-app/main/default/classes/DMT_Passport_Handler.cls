global with sharing class DMT_Passport_Handler implements Callable {
    FINAL PRIVATE STATIC STRING STATUSOPPAPPROVAL = 'Approval';
    FINAL PRIVATE STATIC STRING START_CASE_QUEUED_MSG = 'The workflow request is being processed';
    FINAL PRIVATE STATIC STRING START_CASE_QUEUE_ERROR_MSG = 'Unable to enqueue workflow request: ';

    public Object call(String action, Map<String, Object> args) {

        try {
            Map<String, Object> input = (Map<String, Object>)args.get('input');
            Map<String, Object> output = (Map<String, Object>)args.get('output');
            Map<String, Object> options = (Map<String, Object>)args.get('options');

            return invokeMethod(action, input, output, options);
        } catch (Exception e) {
            System.debug('Exception --> ' + e.getMessage() + ' at line ' + e.getLineNumber());
            List<DMT_AsyncPayload> batchPayloads = new List<DMT_AsyncPayload>();
            batchPayloads.add(new DMT_LogExceptionPayload(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(), 'DMT_Passport_Handler', 'call', 'DMT', ''));
            Database.executeBatch(new DMT_AsyncBatchJob(batchPayloads));
            return new Map<String,Object>{'error' => e.getMessage() + ' at line ' + e.getLineNumber()};
        }
    }

    private static Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        String objectName = DMT_Passport_Helper.objectNameById(String.valueOf(inputMap.get('recordId')));

        if(methodName =='refreshInformation'){

            outMap.put('result', true);
            outMap.put('message', '');

            String payload = DMT_Passport_Helper.setPayloadMin(String.valueOf(inputMap.get('recordId')));

            Map<String, Object> requestMap = new Map<String, Object> {'payload' => payload};

            DMT_Passport_Helper.callConsumptionLimitService(requestMap, outMap);

            return outMap;

        } else {

            String objectId;
            outMap.put('result', true);
            outMap.put('message', '');

            if(objectName == DMT_Line__c.getSObjectType().getDescribe().getName() || objectName == Opportunity.getSObjectType().getDescribe().getName()){
                objectId = String.valueOf(inputMap.get('recordId'));
            } else if(objectName == Passport__c.getSObjectType().getDescribe().getName()){
                Passport__c passport = [SELECT Id, DMT_Line__c, Opportunity__c FROM Passport__c WHERE Id = :(Id)inputMap.get('recordId') WITH USER_MODE];

                if(passport.DMT_Line__c != null) {
                    objectId = passport.DMT_Line__c;
                } else {
                    objectId = passport.Opportunity__c;
                }
            }
            system.debug('antes hpg');
            String payload = DMT_Passport_Helper.setPayloadPassport(objectId, (String)inputMap.get('clientsGroup'));
            system.debug('despues hpg');
            Map<String, Object> requestMap = new Map<String, Object> {'payload' => payload};

            Passport__c passport;
            String objectType = DMT_Passport_Helper.objectNameById(objectId);

            // 1. Identify the Passport Record
            if (objectType == Opportunity.getSObjectType().getDescribe().getName()) {
                passport = DMT_Passport_Selector.passportByIdOpportunity(objectId);
            } else {
                passport = DMT_Passport_Selector.getPassport(objectId);
            }

            // 2. Put ID in map for markAsObsolete later
            if (passport != null) {
                outMap.put('passportId', passport.Id);
            }

            // 3. Unified Gatekeeper
            Boolean isOpp = (objectType == Opportunity.getSObjectType().getDescribe().getName());
            Boolean isForced = (Boolean) Boolean.valueOf((String) inputMap.get('forceCall'));
            Boolean isObsolete = passport.DMT_Is_Obsoleted_Passport_Save__c;
            Boolean isEmpty = String.isEmpty(passport.DMT_Passport_Save__c);

            if (isOpp || isForced || isObsolete || isEmpty) {
                system.debug(LoggingLevel.INFO, 'LOG-APEX: Executing Evaluation Service Callout');
                DMT_Passport_Helper.callPassportService(passport, requestMap, outMap, objectType);
                System.debug(LoggingLevel.INFO, 'Returned from DMT_Passport_Helper.callPassportService');
            }

            return outMap;
        }
    }

    @AuraEnabled
    public static String buttonCallPassport(String recordId, String clientesGroup){
        String objectName = DMT_Passport_Helper.objectNameById(recordId);
        System.debug('logs::buttonCallPassport recordId: ' + recordId + ' objectName: ' + objectName + ' clientesGroup: ' + clientesGroup);
        try {
            Boolean userPermission = false;
            if(objectName == DMT_Line__c.getSObjectType().getDescribe().getName()) {
                Passport__c passport = DMT_Passport_Selector.getPassport(recordId);
                userPermission = calculatePermission(passport.DMT_Line__r.OwnerId, DMT_Passport_Selector.getTeamMember(recordId));
            } else if(objectName == Passport__c.getSObjectType().getDescribe().getName()) {
                Passport__c passport = DMT_Passport_Selector.passportById(recordId);
                if(passport.DMT_Line__c != null) {
                    userPermission = calculatePermission(passport.DMT_Line__r.OwnerId, DMT_Passport_Selector.getTeamMember(passport.DMT_Line__c));
                } else {
                    userPermission = calculatePermission(passport.Opportunity__r.OwnerId, DMT_Passport_Selector.getTeamMemberOpportunity(passport.Opportunity__c));
                }
            } else if(objectName == Opportunity.getSObjectType().getDescribe().getName()) {
                Passport__c passport = DMT_Passport_Selector.passportByIdOpportunity(recordId);
                userPermission = calculatePermission(passport.Opportunity__r.OwnerId, DMT_Passport_Selector.getTeamMemberOpportunity(passport.Opportunity__c));
            }

            if(userPermission) {
                return JSON.serialize(invokeMethod(null, new Map<String, Object>{'recordId' => recordId, 'forceCall' => 'true', 'clientsGroup' => clientesGroup}, new Map<String, Object>(), null));
            }

            return JSON.serialize(new Map<String, Object>{'result' => false, 'message' => 'You do not have permission to generate the passport'});

        } catch (Exception e) {
            System.debug('An error occurred in DMT_Passport_Handler.buttonCallPassport: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            System.debug('stack trace, ' + e.getStackTraceString());
            List<DMT_AsyncPayload> batchPayloads = new List<DMT_AsyncPayload>();
            batchPayloads.add(new DMT_LogExceptionPayload(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(), 'DMT_Passport_Handler', 'buttonCallPassport', 'DMT', ''));
            Database.executeBatch(new DMT_AsyncBatchJob(batchPayloads));
            Map<String, Object> errorResponse = new Map<String, Object>{'error' => e.getMessage() + ' at line ' + e.getLineNumber()};
            return JSON.serialize(errorResponse);
        }
    }

    @AuraEnabled(cacheable=true)
    public static string getInformationPassport(String recordId) {
        Map<String, Object> response = new Map<String, Object>();
        List<Id> tasksId = new List<Id>();

        String objectName = DMT_Passport_Helper.objectNameById(recordId);

        try {
            Passport__c passport = new Passport__c();
            if(objectName == DMT_Line__c.getSObjectType().getDescribe().getName()) {
                passport = DMT_Passport_Selector.getPassport(recordId);
                response = mapLineOpp(passport,DMT_Line__c.getSObjectType().getDescribe().getName());
            }
            else if(objectName == Passport__c.getSObjectType().getDescribe().getName()) {
                passport = DMT_Passport_Selector.passportById(recordId);
                if(passport.DMT_Line__c != null) {
                    response = mapLineOpp(passport,DMT_Line__c.getSObjectType().getDescribe().getName());
                } else if(passport.Opportunity__c != null) {
                    response = mapLineOpp(passport,Opportunity.getSObjectType().getDescribe().getName());
                }
            } else if (objectName == Opportunity.getSObjectType().getDescribe().getName()) {

                passport = DMT_Passport_Selector.passportByIdOpportunity(recordId);
                response = mapLineOpp(passport,Opportunity.getSObjectType().getDescribe().getName());

            }

            return JSON.serialize(response);
        } catch (Exception e) {
            System.debug('An error occurred in DMT_Passport_Handler.getInformationPassport: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            List<DMT_AsyncPayload> batchPayloads = new List<DMT_AsyncPayload>();
            batchPayloads.add(new DMT_LogExceptionPayload(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(), 'DMT_Passport_Handler', 'getInformationPassport', 'DMT', ''));
            Database.executeBatch(new DMT_AsyncBatchJob(batchPayloads));
            Map<String, Object> errorResponse = new Map<String, Object>{'error' => e.getMessage() + ' at line ' + e.getLineNumber()};
            return JSON.serialize(errorResponse);
        }
    }

    private static Map<String, Object> mapLineOpp(Passport__c passport, String entity) {
        Map<String, Object> response = new Map<String, Object>();
        List<Id> tasksId = new List<Id>();

        if(entity == 'DMT_Line__c'){

        List<Task> tasks = DMT_Passport_Selector.getTask(passport.DMT_Line__c);

        for(Task t : tasks) {
            tasksId.add(t.Id);
        }

        response.put('externalId', passport.DMT_Line__r.Line_Id__c);
        response.put('lineId', passport.DMT_Line__c);
        response.put('passportId', passport.Id);
        response.put('tasksId', JSON.serialize(tasksId));
        response.put('userPermission', calculatePermission(passport.DMT_Line__r.OwnerId, DMT_Passport_Selector.getTeamMember(passport.DMT_Line__c)));
        response.put('recordType', passport.DMT_Line__r.RecordType.DeveloperName);
        response.put('additional_Restrictions', passport.DMT_Line__r.DMT_Additional_Restrictions__c);
        response.put('groupMembers', JSON.serialize(DMT_Passport_Selector.getUserGroupMembers()));

        } else if ( entity == 'Opportunity'){

            List<Task> tasks = DMT_Passport_Selector.getTaskbyOpp(passport.Opportunity__c);

            for(Task t : tasks) {
                tasksId.add(t.Id);
            }

            response.put('opportunityId', passport.Opportunity__c);
            response.put('externalId', passport.Opportunity__r.DMT_Opp_Id__c);
            response.put('passportId', passport.Id);
            response.put('tasksId', JSON.serialize(tasksId));
            response.put('userPermission', calculatePermission(passport.Opportunity__r.OwnerId, DMT_Passport_Selector.getTeamMemberOpportunity(passport.Opportunity__c)));
            response.put('recordType', passport.Opportunity__r.RecordType.DeveloperName);
            response.put('groupMembers', JSON.serialize(DMT_Passport_Selector.getUserGroupMembers()));

        }

        return response;
    }

    @AuraEnabled()
    public static Map<String, Object> startCase(String externalLineid, String approverId,String taskId, List<Map<String, Object>> taskList, String featureId, String featureName, String comment, String passportSanction) {
            String errorMessage = '';
            final String SUCCESS = 'success';
            final String MESSAGE = 'message';
            final String TXT_SUCCESS_MSG = 'The workflow has been successfully requested';
            final String TXT_ERROR_MSG_NO_APPROVER = 'We can\'t find the approver to assign step ';
            final String TXT_ERROR_MSG_NO_TASK_TYPE = 'We can\'t find the task type ';
            final String TXT_ERROR_MSG_FEATURE_STARTED = 'The request for this feature is already started, please update the passport ';
            final String TXT_ERROR_MSG_RECORD_NOT_FOUND = 'No record (Line or Opportunity) was found for the ID:';
            String taskIdSf;
            String caseId;

            Map<String, Object> result = new Map<String, Object>();
            result.put(SUCCESS, false);
            result.put(MESSAGE, '');

        try {
            
            String lineOppId = null;
            
            DMT_Line__c line;
            Opportunity opp;
            Id aproverId = DMT_Passport_Selector.getAppproverId(approverId);
            List<DMT_Task_Type__c> taskType = DMT_Passport_Selector.getTaskType(taskId);
            List<DMT_Line__c> lineFromQuery = DMT_Passport_Selector.getLineByExternalId(externalLineid);
            
            if(lineFromQuery.size() > 0){
                line = lineFromQuery[0];
                lineOppId = line.Id;
            }
            else{
                List<Opportunity> oppFromQuery =  DMT_Passport_Selector.getOpportunity(externalLineid);
                if (oppFromQuery.size() > 0) {
                    opp = oppFromQuery[0];
                    lineOppId = opp.Id;
                    if(opp.StageName == STATUSOPPAPPROVAL){
                        String lineid = DMT_Passport_Helper.createSanctionFromOpp(opp.Id,approverId);
                        if(lineid != null){
                            line = new DMT_Line__c(Id = lineid, Client__c = opp.AccountId);
                        }
                    }
                } else {
                    opp = null;
                }
            }

            if (lineOppId == null) {
                errorMessage=TXT_ERROR_MSG_RECORD_NOT_FOUND + externalLineid;
                result.put(SUCCESS, false);
                result.put(MESSAGE, errorMessage);
                return result;
            }
            List<Task> approvalEditTasks = DMT_Passport_Selector.getApprovalEditTasks(lineOppId);
            List<Case> featureCase = DMT_Passport_Selector.getCaseByLineFeature(lineOppId, featureId);

            if( aproverId==null ){
                errorMessage=TXT_ERROR_MSG_NO_APPROVER;
                result.put(SUCCESS, false);
                result.put(MESSAGE, errorMessage);
                return result;
            }

            if(taskType.isEmpty()){
                errorMessage=TXT_ERROR_MSG_NO_TASK_TYPE;
                result.put(SUCCESS, false);
                result.put(MESSAGE, errorMessage);
                return result;

            }

            if(taskType[0].DMT_ApprovalEdit__c && !approvalEditTasks.isEmpty() && line != null && line.DMT_Status_Completed__c == DMT_Constants.APPROVAL){
                errorMessage='The approver ' + approvalEditTasks[0].Owner.Name +' with the task ' + approvalEditTasks[0].DMT_Task_Type__r.Name + ' is blocking the approval editing of the line';
                result.put(SUCCESS, false);
                result.put(MESSAGE, errorMessage);
                return result;
            }

            if(!featureCase.isEmpty()){
                errorMessage=TXT_ERROR_MSG_FEATURE_STARTED;
                result.put(SUCCESS, false);
                result.put(MESSAGE, errorMessage);
                return result;

            }else{
                Case newCase = DMT_Passport_Helper.createCase(line, opp, aproverId, featureId,featureName, taskList, comment, passportSanction);
                System.debug('DMT_Passport_Handler.startCase newCase: ' + newCase.id + 'aproverId  ' + aproverId + 'taskType  '+  taskType[0]);
                caseId = newCase.Id;
                Task newTask = DMT_Passport_Helper.createTask(newCase.Id, aproverId, taskType[0]);
                taskIdSf = newTask.Id;
            }

            result.put(SUCCESS, true);
            result.put(MESSAGE, TXT_SUCCESS_MSG);
            result.put('TASK', taskIdSf);
            result.put('CASE', caseId);

            return result;

        } catch (Exception e) {
            // CIBGLOBALD-4477 - goes through the orchestrator rather than Database.executeBatch: executeBatch is illegal
            // when startCase is reached from a Batch execute (DMT_AsyncBatchJob) and would replace the
            // real error with an AsyncException. The orchestrator picks a legal context (Batch,
            // Queueable) on its own. Flushed here because startCase is also an @AuraEnabled entry
            // point, where nothing downstream is guaranteed to flush the buffer.
            DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(), 'DMT_Passport_Handler', 'startCase', 'DMT', ''));
            DMT_AsyncOrchestrator.flush();

            result.put(SUCCESS, false);
            result.put(MESSAGE, String.isBlank(errorMessage) ? e.getMessage() : errorMessage);
            return result;


        }

    }

    @AuraEnabled(cacheable=true)
    public static String getLastDay() {
        return DMT_HPG_Utils.lastDate();
    }

    public static Boolean calculatePermission (Id userId, List<DMT_TeamMember__c> memberLst) {
        Boolean userPermission = UserInfo.getUserId() == userId;

        Boolean userPermissionRole = DMT_Utils.hasWriteAccess();
        Boolean userHasGodLineAccess = DMT_Utils.checkLineGodUser();

        for(DMT_TeamMember__c m : memberLst) {
            if(m.AccessLevel__c == 'Edit' || m.AccessLevel__c == 'All') {
                userPermission = true;
                break;
            }
        }

        return (userPermission && userPermissionRole) || userHasGodLineAccess;
    }


    @AuraEnabled(cacheable=true)
    public static Boolean calculatePermissionLWC(String recordId) {
        DMT_Line__C line = DMT_Passport_Selector.getLine(recordId);
        return calculatePermission(line.OwnerId, DMT_Passport_Selector.getTeamMember(recordId));
    }

    @AuraEnabled(cacheable=true)
    public static List<DMT_Fuature_Rule__c> getFeatureRulesLWC() {
        List<DMT_Fuature_Rule__c> featureRules = DMT_Passport_Selector.getFeatureRulesDMTO();
        return featureRules;
    }

    /**
    * @description validateOppBeforePassport: This method is used to validate the opportunity before call the passport service.
    * 02/01/2025 delete validatión, now passport its always callable and response will have the validations
    * @author BBVA DMT | 16-10-2025
    * @param oppId
    * @return Map<String, Object>
    **/
    @AuraEnabled
    public static Map<String,Object> validateOppBeforePassport(Id oppId) {
        Map<String,Object> response = new Map<String,Object>();
        response.put('success', true);
        response.put('message', new List<String>());
        return response;
    }

    @AuraEnabled(cacheable=false)
    public static List<Map<String,String>> getFeatureTypeByApproverType(List<String> featuresApproverIds) {
        final String  RISK_FEATURE = 'Risk';
        final String  BUSINESS_FEATURE = 'Business';
        final String TXT_EXCEPTION_ACCESS = 'You do not have access to the DMT_Approver__c object:';
        List<Map<String,String>> featureTypeListMapByIdApprover = new List<Map<String,String>>();
        List<DMT_Approver__c> approversList = new List<DMT_Approver__c>();
        try{
            approversList = DMT_Passport_Selector.getApprovers(featuresApproverIds);
        } catch (Exception e) {
            throw new AuraHandledException(TXT_EXCEPTION_ACCESS +e);
        }

        if(approversList.isEmpty()) {
            return featureTypeListMapByIdApprover;
        }

        for (DMT_Approver__c approver : approversList) {
            string featureType = null;
            if (approver.DMT_ApproverType__r?.Name == RISK_FEATURE) {
                featureType= RISK_FEATURE;
            } else if (approver.DMT_ApproverType__r?.Name == BUSINESS_FEATURE) {
                featureType=BUSINESS_FEATURE;
            }
            if(featureType!=null){
                featureTypeListMapByIdApprover.add(new Map<String,String>{ 'approverId' => approver.DMT_External_Id__c, 'featureType' => featureType });
            }
        }

        return featureTypeListMapByIdApprover;
    }

    /**
     * @description Centralized worker for Trigger-based passport updates.
     * Executed by the Async Dispatcher (Queueable/Batch context).
     */
    public static void handlePassportIntegration(DMT_PassportPayload payload) {
        Map<String, Object> outMap = new Map<String, Object>();
        Id passportRecordId;

        System.debug('LOG-APEX: Starting trigger-initiated passport update for recordId ' + payload.recordId);
        System.debug('LOG-APEX: Payload clientId ' + payload.clientId);
        System.debug('LOG-APEX: Payload serviceName ' + payload.serviceName);

        try {
            // PRE-FLIGHT: Identify the Passport ID immediately so we have it for the catch block.
            String objectType = DMT_Passport_Helper.objectNameById(payload.recordId);
            Passport__c p;
            if (objectType == Opportunity.getSObjectType().getDescribe().getName()) {
                p = DMT_Passport_Selector.passportByIdOpportunity(payload.recordId);
            } else {
                p = DMT_Passport_Selector.getPassport(payload.recordId);
            }

            if (p != null) {
                passportRecordId = p.Id;
            }

            // 1. Step 1: HPG Fetch
            String lastDate = DMT_HPG_Utils.lastDate();
            List<String> countries = new List<String> {'All'};
            DMT_HPG_GlobalPosition.Wrapper hpgWrapper = new DMT_HPG_GlobalPosition.Wrapper();
            
            Object res = DMT_HPG_MainTableCustomController.fetchData('passport', payload.clientId, countries, lastDate, 'Y/N', '1', '5000', String.valueOf(payload.clientId));
            hpgWrapper = (DMT_HPG_GlobalPosition.Wrapper) JSON.deserialize(JSON.serialize(res), DMT_HPG_GlobalPosition.Wrapper.class);
            
            String clientsGroupJson = JSON.serialize(hpgWrapper.data);

            // 2. Step 2: Invoke the existing logic directly
            Map<String, Object> inputMap = new Map<String, Object>{
                'recordId' => payload.recordId, 
                'forceCall' => 'true', 
                'clientsGroup' => clientsGroupJson
            };
            
            invokeMethod(null, inputMap, outMap, null);

            // If the service reports a business failure
            if (outMap.get('result') == false) {
                markAsObsolete(passportRecordId);
            }

            System.debug('LOG-APEX: Trigger-initiated passport update finished.');

        } catch (Exception e) {
            // FATAL CRASH HANDLING
            // Because we fetched passportRecordId at the very top, it is rarely null here.
            if (passportRecordId != null) {
                System.debug(LoggingLevel.ERROR, 'Marking Passport ' + passportRecordId + ' as obsolete due to: ' + e.getMessage());
                System.debug(LoggingLevel.ERROR, 'StackTrace: ' + e.getStackTraceString());
                markAsObsolete(passportRecordId);
            }
            
            // We still throw the error so the AsyncBatchJob catches it and writes it to DES_Exceptions__b
            throw e; 
        }
    }

    @TestVisible
    private static void markAsObsolete(Id passportId) {
        if (passportId == null) {
            return;
        }
        Passport__c p = new Passport__c(Id = passportId, DMT_Is_Obsoleted_Passport_Save__c = true);
        
        // SYSTEM_MODE ensures we bypass the user's CRUD/FLS restrictions
        Database.update(p, AccessLevel.SYSTEM_MODE);
    }

    @AuraEnabled
    public static Map<String,Object> getMainHolderAccountId(Id oppId) {
        try {
            if (oppId == null) {
                throw new AuraHandledException('No Opportunity Id provided');
            }
            return DMT_Passport_Helper.resolveMainHolderAccountId(oppId);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            DES_Exception_Utils.logException(e, 'DMT_Passport_Helper', 'getMainHolderAccountId', 'DMT', '');
            throw new AuraHandledException(e.getMessage());
        }
    }

}