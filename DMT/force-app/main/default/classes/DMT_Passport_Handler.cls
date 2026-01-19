global with sharing class DMT_Passport_Handler implements Callable {

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
                Passport__c passport = [SELECT Id, DMT_Line__c, Opportunity__c FROM Passport__c WHERE Id = :(Id)inputMap.get('recordId') WITH SECURITY_ENFORCED];

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
            if( objectType == Opportunity.getSObjectType().getDescribe().getName()){
                passport = DMT_Passport_Selector.passportByIdOpportunity(objectId);
                DMT_Passport_Helper.callPassportService(passport,requestMap, outMap, objectType);
            }
            else{
                passport = DMT_Passport_Selector.getPassport(objectId);
            }
            if( (objectType != Opportunity.getSObjectType().getDescribe().getName()) && ( passport.DMT_Is_Obsoleted_Passport_Save__c || String.isEmpty(passport.DMT_Passport_Save__c) || (Boolean) Boolean.valueOf( (String) inputMap.get('forceCall')))) {
                system.debug('antes dmto');

                DMT_Passport_Helper.callPassportService(passport,requestMap, outMap, objectType);
                system.debug('despues dmto');
            }

            return outMap;
        }
    }

    @AuraEnabled
    public static String buttonCallPassport(String recordId, String clientesGroup){
        String objectName = DMT_Passport_Helper.objectNameById(recordId);
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
            response.put('userPermission', calculatePermission(passport.Opportunity__r.OwnerId, DMT_Passport_Selector.getTeamMember(passport.Opportunity__c)));
            response.put('recordType', passport.Opportunity__r.RecordType.DeveloperName);
            response.put('groupMembers', JSON.serialize(DMT_Passport_Selector.getUserGroupMembers()));

        }

        return response;
    }

    @AuraEnabled()
    public static Boolean startCase(String externalLineid, String approverId,String taskId, List<Map<String, Object>> taskList, String featureId, String featureName, String comment, String passportSanction) {
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
                    String lineid = DMT_Passport_Helper.createSanctionFromOpp(opp.Id,approverId);
                    if(lineid != null){
                        line = new DMT_Line__c(Id = lineid, Client__c = opp.AccountId);
                    }
                } else {
                    opp = null;
                }
            }
            if (lineOppId == null) {
                throw new AuraHandledException('No record (Line or Opportunity) was found for the ID:' + externalLineid);
            }
            List<Task> approvalEditTasks = DMT_Passport_Selector.getApprovalEditTasks(lineOppId);
            List<Case> featureCase = DMT_Passport_Selector.getCaseByLineFeature(lineOppId, featureId);
            if( aproverId==null ){
                throw new AuraHandledException('We can\'t find the approver to assign step');
            }

            if(taskType.isEmpty()){
                throw new AuraHandledException('We can\'t find the task type');

            }

            if(taskType[0].DMT_ApprovalEdit__c && !approvalEditTasks.isEmpty() && line.DMT_Status_Completed__c == DMT_Constants.APPROVAL){
                throw new AuraHandledException('This feature cannot be requested yet because the approver ' + approvalEditTasks[0].Owner.Name +' with the task ' + approvalEditTasks[0].DMT_Task_Type__r.Name + ' is blocking the approval editing of the line');
            }

            if(!featureCase.isEmpty()){
                throw new AuraHandledException('The request for this feature is already started, please update the passport.');

            }else{
                Case newCase = DMT_Passport_Helper.createCase(line, opp, aproverId, featureId,featureName, taskList, comment, passportSanction);
                System.debug('DMT_Passport_Handler.startCase newCase: ' + newCase.id + 'aproverId  ' + aproverId + 'taskType  '+  taskType[0]);

                Task newTask = DMT_Passport_Helper.createTask(newCase.Id, aproverId, taskType[0]);
            }

            return true;
        } catch (Exception e) {
            System.debug('An error occurred in DMT_Passport_Handler.startCase: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            List<DMT_AsyncPayload> batchPayloads = new List<DMT_AsyncPayload>();
            batchPayloads.add(new DMT_LogExceptionPayload(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(), 'DMT_Passport_Handler', 'startCase', 'DMT', ''));
            Database.executeBatch(new DMT_AsyncBatchJob(batchPayloads));
            return false;
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


}