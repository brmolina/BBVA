/**
 * @description       : Controller class for DMT_Case_Steps LWC
 * @author            : Aníbal Cortés
 * @group             :
 * @last modified on  : 09-03-2024
 * @last modified by  : Aníbal Cortés
 **/
public without sharing class DMT_Case_Steps_Controller {

    /**
     * @description Method that retrieves the steps from the user that is executing the code
     * @author Aníbal Cortés | 09-05-2024
     * @return Map<Id, WRAPPER_Step>
     **/
    @AuraEnabled(cacheable=true)
    public static List<WRAPPER_Step> getStepsFromUser() {

        List<DMT_Approver_Member__c> members = DMT_Case_Steps_Selector.getApproverMembersByUser(UserInfo.getUserId());

        Set<String> groupsDeveloperName = new Set<String>();

        for (DMT_Approver_Member__c member : members) {
            groupsDeveloperName.add(member.DMT_Approver__r.DMT_Group__c);
        }

        Map<Id, Group> queuesIds = new Map<Id, Group>(DMT_Case_Steps_Selector.getGroupsByDeveloperName(groupsDeveloperName));

        Map<Id, Task> tasksMap = new Map<Id, Task>(DMT_Case_Steps_Selector.getTasksByOwner(queuesIds.keySet()));

        Map<Id,List<Task>> casesWithTaskMap = new Map<Id,List<Task>>();
        Map<Id,Set<Id>> casesWithTaskIdMap = new Map<Id,Set<Id>>();

        for (Task task : tasksMap.values()) {
            //List<Task> taskWithCase = new List<Task>();
            Set<Id> idTaskWithCase = new Set<Id>();
            if(casesWithTaskMap.get(task.Id)!=null){
                //taskWithCase = casesWithTaskMap.get(task.WhatId);
                idTaskWithCase = casesWithTaskIdMap.get(task.WhatId);
            }

            idTaskWithCase.add(task.Id);
            casesWithTaskIdMap.put(task.WhatId, idTaskWithCase);

            //taskWithCase.add(task);
            //casesWithTaskMap.put(task.whatId,taskWithCase);
        }
        Map<Id, Case> casesMap = new Map<Id, Case>(DMT_Case_Steps_Selector.getCasesByIdAndOwner(queuesIds.keySet(),casesWithTaskIdMap.keySet()));

        //List<Task> tasks = new List<Task>();
        Set<Id> taskIds = new Set<Id>();
        for(Id caseId : casesMap.keySet()){
            //tasks.addAll(casesWithTaskMap.get(caseId) );
            taskIds.addAll(casesWithTaskIdMap.get(caseId) );
        }



        Map<Id, Task> restOfTasks = DMT_Case_Steps_Selector.getTasksByNotInTaskMap(casesMap.keySet(),taskIds);
        taskIds.addAll(restOfTasks.keySet());

        List<Task> tasks = DMT_Case_Steps_Selector.getTasksById(taskIds);

        return processTasksFromCases(tasks);

    }

    public static List<WRAPPER_Step> processTasksFromCases(List<Task> tasks) {
        Map<Id, List<Task>> caseIdWithTasks = new Map<Id, List<Task>>();
        Map<String, String> resultTaskMap = new Map<String, String>{'Yes' => String.valueOf(Schema.DMT_Task_Type__c.DMT_Yes_Flag__c), 'No' => String.valueOf(Schema.DMT_Task_Type__c.DMT_No_Flag__c), 'NA' => String.valueOf(Schema.DMT_Task_Type__c.DMT_NA_Flag__c)};

        for (Task task : tasks) {
                        List<Task> tasksWithCase = new List<Task>();
            if (caseIdWithTasks.containsKey(task.WhatId)) {
                tasksWithCase = caseIdWithTasks.get(task.WhatId);
            }
            tasksWithCase.add(task);
            caseIdWithTasks.put(task.WhatId, tasksWithCase);
        }

        Map<Id, Case> cases = new Map<Id, Case>(DMT_Case_Steps_Selector.getCasesFromTasks(caseIdWithTasks.keySet()));

        // Get fields dynamically (DMT_FieldsHistoryView__c) from approver member
        List<DMT_Approver_Member__c> members = DMT_Case_Steps_Selector.getApproverMembersByUser(UserInfo.getUserId());

        // Map the developerName of the queue with the JSON configuration (DMT_FieldsHistoryView__c) of that approver member
        Map<String, String> userSpecificFieldsMap = new Map<String, String>();
        for (DMT_Approver_Member__c member : members) {
            String devName = member.DMT_Approver__r.DMT_Group__c;
            if (!userSpecificFieldsMap.containsKey(devName)) {
                userSpecificFieldsMap.put(devName, member.DMT_FieldsHistoryView__c);
            }
        }

        // Get the DeveloperName of the queues (Group) associated with the OwnerId of the Tasks
        Set<Id> queueIds = new Set<Id>();
        for (Task task : tasks) {
            if (task.OwnerId != null && String.valueOf(task.OwnerId).startsWith('00G')) {
                queueIds.add(task.OwnerId);
            }
        }
        Map<Id, Group> ownerIdToGroup = new Map<Id, Group>([SELECT Id, DeveloperName FROM Group WHERE Id IN :queueIds WITH USER_MODE]);

        // Get labels from the Custom Metadata
        Map<String, String> pathToLabel = new Map<String, String>();
        for (DMT_ApproverMemberFields__mdt meta : [SELECT Label, DMT_ObjectLookup__c, DMT_FieldApiName__c FROM DMT_ApproverMemberFields__mdt]) {
            String fullPath = meta.DMT_ObjectLookup__c + '.' + meta.DMT_FieldApiName__c;
            pathToLabel.put(fullPath, meta.Label);
        }

        Map<Id, WRAPPER_Step> tasksForCase = new Map<Id, WRAPPER_Step>();
        WRAPPER_Step parentStep = new WRAPPER_Step();
        parentStep.itemLabel = 'Closed Lines/Opportunities';
        parentStep.itemKey = 'Closed';
        parentStep.itemKeyAsLink = false;
        Boolean hasClosed = false;
        parentStep.subitems = new List<WRAPPER_Step>();

        WRAPPER_Step parentStepFinished = new WRAPPER_Step();
        parentStepFinished.itemLabel = 'Returned to requester';
        parentStepFinished.itemKey = 'Finished';
        parentStepFinished.itemKeyAsLink = false;
        Boolean hasFinished = false;
        parentStepFinished.subitems = new List<WRAPPER_Step>();

        for (Id caseId : caseIdWithTasks.keySet()) {
            WRAPPER_Step step = new WRAPPER_Step();
            step.subitems = new List<WRAPPER_Step>();

            for (Integer i = 0; i < caseIdWithTasks.get(caseId).size() && cases.get(caseId) != null;  i++) {
                Task task = caseIdWithTasks.get(caseId).get(i);
                WRAPPER_Step subStep = new WRAPPER_Step();
                subStep.id = i;
                substep.committeeLabel = task.DMT_Committee_Label__c;
                substep.approver = task.Owner.Name;
                substep.status = task.Status;
                substep.step = new WRAPPER_Url();
                substep.step.urlLabel = task.DMT_Task_Type__r.Name != null ? task.DMT_Task_Type__r.Name : task.Id;
                substep.lineOrOpportunity = cases.get(caseId).DMT_LineOpportunity__c;
                substep.oppLineName = new WRAPPER_Url();
                substep.oppLineName.urlLabel = cases.get(caseId).DMT_LineOpportunity__c == 'O' ? cases.get(caseId).opportunity_id__r.Name : cases.get(caseId).DMT_Line__r.Name;
                substep.description = cases.get(caseId).description;
                substep.oppLineName.urlValue = cases.get(caseId).DMT_LineOpportunity__c == 'O' ? '/' + cases.get(caseId).opportunity_id__c : '/' + cases.get(caseId).DMT_Line__c;
                substep.lineDetails = cases.get(caseId).DMT_Line__r != null ? String.valueOf(cases.get(caseId).DMT_Line__r.Line_Details__c) : '';
                substep.client = cases.get(caseId).Account?.Name;
                substep.startDate = task.CreatedDate.format('dd/MMM/yyyy HH:mm:ss');
                substep.endDate = task.DMT_Completed_Date_Time__c != null ? task.DMT_Completed_Date_Time__c.format('dd/MMM/yyyy HH:mm:ss') : (task.CompletedDateTime != null ? task.CompletedDateTime.format('dd/MMM/yyyy HH:mm:ss')  : '');
                substep.user = task.DMT_UserClosedTask__c != null ? task.DMT_UserClosedTask__r.Name : task.LastModifiedBy.Name;
                substep.result = (String)(resultTaskMap.containsKey(task.DMT_Step_Result__c) && (task.getSobject('DMT_Task_Type__r') != null) ? task.getSobject('DMT_Task_Type__r').get((String)resultTaskMap.get(task.DMT_Step_Result__c)) : '');
                substep.rawresult = task.DMT_Step_Result__c;
                substep.taskId = task.Id;
                substep.caseId = caseId;
                substep.lineOpportunityDateToProposal  = cases.get(caseId).DMT_LineOppDateToProposal__c != null ? cases.get(caseId).DMT_LineOppDateToProposal__c.format('dd/MMM/yyyy HH:mm:ss') : '';
                substep.description = task.Description;
                substep.featureId = cases.get(caseId).DMT_Feature_Id__c;
                substep.featureName = cases.get(caseId).DMT_Related_feature_name__c;
                substep.featureType = cases.get(caseId).DMT_Passport_Sanction__c;
                substep.lineOppStatus = cases.get(caseId).DMT_LineOpportunity__c == 'O' ? cases.get(caseId).opportunity_id__r.StageName : cases.get(caseId).DMT_Line__r.Status__c;
                //Added fields of OpportunityId and LineId, also added the group Client Name
                substep.lineOppId = cases.get(caseId).DMT_LineOpportunity__c == 'O' ? cases.get(caseId).opportunity_id__r.DMT_Opp_Id__c : cases.get(caseId).DMT_Line__r.Line_Id__c;
                substep.groupClientName = cases.get(caseId).Account.DES_Client_Type__c == 'CIB Group' ? cases.get(caseId).Account.Name : cases.get(caseId).Account.DES_Main_Parent__r.Name;
                substep.caseStatus = cases.get(caseId).Status;
                substep.taskSize = cases.get(caseId).Tasks.size();

                // Get DeveloperName from the Queue
                String queueDevName = ownerIdToGroup.get(task.OwnerId)?.DeveloperName;
                // Get approver member fields
                String fieldsJson = userSpecificFieldsMap.get(queueDevName);

                // If the approver member does not have the fields configured, do not show additional details
                if (String.isBlank(fieldsJson)) {
                    substep.taskDetails = '';
                } else {
                    List<String> taskDetailsParts = new List<String>();
                    try {
                        Map<String, Object> fieldsMap = (Map<String, Object>) JSON.deserializeUntyped(fieldsJson);

                        for (Object pathObj : fieldsMap.values()) {
                            String path = (String) pathObj;
                            Boolean isLinePath = path != null && path.startsWith('DMT_Line__r.');
                            Boolean isOpportunityPath = path != null && path.startsWith('opportunity_id__r.');

                            // If the path starts with DMT_Line__r or opportunity_id__r it means that it is a field of the opportunity or line
                            if ((cases.get(caseId).DMT_LineOpportunity__c == 'L' && isLinePath) || (cases.get(caseId).DMT_LineOpportunity__c == 'O' && isOpportunityPath)) {
                                try {
                                    Object value = getFieldValueFromPath(cases.get(caseId), path);
                                    if (value != null && String.valueOf(value).trim() != '') {
                                        // Join label + value
                                        String label = pathToLabel.containsKey(path) ? pathToLabel.get(path) : path;
                                        taskDetailsParts.add(label + ': ' + String.valueOf(value));
                                    }
                                } catch (Exception e) {
                                    DES_Exception_Utils.logException(e,'DMT_Case_Steps_Controller', 'processTasksFromCases', 'DMT', '');
                                }
                            }
                        }
                    } catch (Exception e) {
                        DES_Exception_Utils.logException(e,'DMT_Case_Steps_Controller', 'processTasksFromCases', 'DMT', '');
                    }

                    // Join all parts with semicolons or return empty string
                    substep.taskDetails = taskDetailsParts.isEmpty() ? '' : String.join(taskDetailsParts, ' ; ');
                }

                if (i != 0) {
                    substep.sameAsSubItems = true;
                    substep.step.urlValue = 'c-modal-container';
                    substep.itemKey = cases.get(caseId).CaseNumber + '_' + task.Id;
                    step.subitems.add(substep);

                } else {
                    substep.sameAsSubItems = true;
                    substep.itemKey = cases.get(caseId).CaseNumber + '_' + task.Id;
                    if (cases.get(caseId).Status.equalsIgnoreCase('Finished')) {
                        substep.step.urlValue = 'c-modal-container';
                    } else {
                        substep.step.urlValue = '/' + caseId;
                    }
                    substep.subitems = new List<WRAPPER_Step>();
                    step = substep;
                }

            }
            if (cases.get(caseId) != null && cases.get(caseId).DMT_LineOpportunity__c != null && ((cases.get(caseId).DMT_LineOpportunity__c.equalsIgnoreCase('L') && cases.get(caseId).DMT_Line__r != null && cases.get(caseId).DMT_Line__r.Status__c != null && cases.get(caseId).DMT_Line__r.Status__c.contains('Closed')) || (cases.get(caseId).DMT_LineOpportunity__c.equalsIgnoreCase('O') && cases.get(caseId).Opportunity_Id__r != null && cases.get(caseId).Opportunity_Id__r.StageName != null && cases.get(caseId).Opportunity_Id__r.StageName.contains('Closed')) || (cases.get(caseId).DMT_LineOpportunity__c.equalsIgnoreCase('L') && cases.get(caseId).DMT_Line__r != null && cases.get(caseId).DMT_Line__r.RecordType != null && (cases.get(caseId).DMT_Line__r.RecordType.DeveloperName == 'TreasurySettlement' || cases.get(caseId).DMT_Line__r.RecordType.DeveloperName == 'OtherProducts') && cases.get(caseId).DMT_Line__r.Booking_Geography__c != null && cases.get(caseId).DMT_Line__r.Booking_Geography__c != 'PE' && cases.get(caseId).DMT_Line__r.Status__c != null && cases.get(caseId).DMT_Line__r.Status__c == DMT_Constants.READYTOCLOSE))) {
                parentStep.subitems.add(step);
                hasClosed = true;
            } else if(cases.get(caseId) != null && cases.get(caseId).Status.equalsIgnoreCase('Finished')) {
                Boolean hasActiveTasks = false;
                for(Task t : caseIdWithTasks.get(caseId)) {
                    if(t.Status != null && (t.Status.equalsIgnoreCase('Not Started') || t.Status.equalsIgnoreCase('In Progress'))) {
                        hasActiveTasks = true;
                        break;
                    }
                }

                if(hasActiveTasks) {
                    tasksForCase.put(caseId, step);
                } else {
                    parentStepFinished.subitems.add(step);
                    hasFinished = true;
                }
            } else {
                tasksForCase.put(caseId, step);
            }
        }

        List<WRAPPER_Step> fullData = tasksForCase.values();
        if(hasFinished) {
            fullData.add(parentStepFinished);
        }
        if (hasClosed) {
            fullData.add(parentStep);
        }
        return fullData;
    }

    private static Object getFieldValueFromPath(SObject source, String path) {
        // Return null if the input path is empty or null
        if (String.isBlank(path)) return null;

        // Split the dot-separated path into segments
        List<String> segments = path.split('\\.');
        // Related Object
        SObject current = source;

        // Iterate over each segment in the path
        for (Integer i = 0; i < segments.size(); i++) {
            // Stop if current object is null
            if (current == null) return null;

            String segment = segments[i];

            try {
                if (i == segments.size() - 1) {
                    //  If this is the last segment, return the final field value
                    return current.get(segment);
                } else {
                    // Navigate into the related object
                    current = (SObject) current.getSObject(segment);
                }
            } catch (Exception e) {
                DES_Exception_Utils.logException(e,'DMT_Case_Steps_Controller', 'getFieldValueFromPath', 'DMT', '');
                return null;
            }
        }

        // Return null if value was not found
        return null;
    }

    @AuraEnabled(cacheable=true)
    public static List<WRAPPER_Step> getStepsFromCase(Id caseId) {

        List<Task> tasks = [SELECT Id, WhatId, Owner.Name, Status, LastModifiedBy.Name, DMT_Completed_Date_Time__c, DMT_UserClosedTask__c, DMT_UserClosedTask__r.Name, CreatedDate, CompletedDateTime, TOLABEL(DMT_Step_Type__c), DMT_Step_Result__c, Description, DMT_Task_Type__r.Name, DMT_Task_Type__r.DMT_Yes_Flag__c, DMT_Task_Type__r.DMT_No_Flag__c, DMT_Task_Type__r.DMT_NA_Flag__c, DMT_Committee_Label__c FROM Task WHERE WhatId =: caseId and RecordType.DeveloperName = 'DMT_Step_Approval' WITH USER_MODE ORDER BY CreatedDate DESC];
        return processTasksFromCases(tasks);

    }

    @AuraEnabled(cacheable=true)
    public static List<WRAPPER_Step> getStepsFromParentCase(Id caseId) {
        Case currentCase = [SELECT ParentId FROM Case WHERE Id = :caseId WITH USER_MODE LIMIT 1];
        if (currentCase.ParentId == null) {
            return new List<WRAPPER_Step>();
        }
        return getStepsFromCase(currentCase.ParentId);
    }

    @AuraEnabled(cacheable=false)
    public static List<WRAPPER_Step> getCurrentStepsFromCases(List<Case> casesList) {
        List<Task> listTaskToProcess = new List<Task>();
        Map<Id,List<Task>> maptasksToProcessByCase = new Map<Id,List<Task>>();
        Set<Id> casesIds = new Set<Id>();

        for(Case c : casesList){
            casesIds.add(c.Id);
        }
        System.debug('casesIds: '+casesIds);
        String queryString = 'SELECT Id, WhatId, Owner.Name, Status, LastModifiedBy.Name, CreatedDate, CompletedDateTime, '
            +' TOLABEL(DMT_Step_Type__c), DMT_Step_Result__c, Description, DMT_Task_Type__r.Name, DMT_Task_Type__r.DMT_Yes_Flag__c, '
                    +'DMT_Task_Type__r.DMT_No_Flag__c, DMT_Task_Type__r.DMT_NA_Flag__c, DMT_UserClosedTask__c, DMT_UserClosedTask__r.Name, DMT_Completed_Date_Time__c, DMT_Committee_Label__c FROM Task '
            +'WHERE WhatId IN (\'' + String.escapeSingleQuotes(String.join(casesIds, '\',\'')) + '\') AND RecordType.DeveloperName = \'DMT_Step_Approval\' ORDER BY CreatedDate DESC ';

        // Llamada al método query
        List<Task> workflowTasks =(List<Task>) DMT_WithoutSharingDAO.query(queryString,'Task');

        for (Task tsk : workflowTasks){
            if(maptasksToProcessByCase.containsKey(tsk.WhatId)) {
                maptasksToProcessByCase.get(tsk.WhatId).add(tsk);
            }else{
                maptasksToProcessByCase.put(tsk.WhatId, new List<Task>{tsk}) ;
            }
        }
        for(Id caseId : maptasksToProcessByCase.keySet()){
            if(!maptasksToProcessByCase.get(caseId).isEmpty()){
                listTaskToProcess.add(maptasksToProcessByCase.get(caseId)[0]);
            }
        }
        System.debug('listTaskToProcess: '+listTaskToProcess?.size());
        return processTasksFromCases(listTaskToProcess);

    }


    @AuraEnabled(cacheable=false)
    public static List<WRAPPER_Step> getStepsFromFeature(String featureId,String lineExternalId) {
        try{
            String queryString = 'SELECT Id, DMT_LineOpportunity__c, opportunity_id__r.Name, Opportunity_Id__r.StageName, DMT_Line__r.Name, DMT_Line__r.Status__c, '
                     + 'Amount__c, Account.Name, CaseNumber, CurrencyIsoCode,DMT_Feature_Id__c, DMT_Passport_Sanction__c '
                + 'FROM Case '
                + 'WHERE DMT_Line__r.Line_Id__c = \'' + String.escapeSingleQuotes(lineExternalId) + '\' '
                + 'AND DMT_Feature_Id__c = \'' + String.escapeSingleQuotes(featureId) + '\'';

            String sObjectType = 'Case';

            // Llamada al método query
            List<Case> worflowCase =(List<Case>) DMT_WithoutSharingDAO.query(queryString, sObjectType);

            /* List<Case> worflowCase = new List<Case>([
            SELECT Id, DMT_LineOpportunity__c, opportunity_id__r.Name, Opportunity_Id__r.StageName, DMT_Line__r.Name, DMT_Line__r.Status__c,
            Amount__c, Account.Name, CaseNumber, CurrencyIsoCode,DMT_Feature_Id__c FROM Case WHERE DMT_Line__r.Line_Id__c=:lineExternalId AND DMT_Feature_Id__c = :featureId LIMIT 1
            ]); */

            if(worflowCase ==null || worflowCase.isEmpty() ){
                return  new List<WRAPPER_Step>();
            }else{
                return getStepsFromCase(worflowCase[0].Id);
            }
        }catch( Exception e){
            DES_Exception_Utils.logException(e,'DMT_Case_Steps_Controller', 'getStepsFromFeature', 'DMT', '');
            throw new AuraHandledException('Error '+e);
        }
    }

    /**
     * FIX: Bulk version - get ALL steps for ALL features in a single batch of queries
     * instead of calling getStepsFromFeature per feature (saves ~40 SOQL queries)
     */
    public static Map<String, List<WRAPPER_Step>> getAllStepsFromFeaturesLine(List<String> featuresIds, String lineExternalId) {
        Map<String, List<WRAPPER_Step>> resultByFeature = new Map<String, List<WRAPPER_Step>>();
        try {
            // 1 single query for ALL features instead of N individual queries
            String queryString = 'SELECT Id, DMT_LineOpportunity__c, opportunity_id__r.Name, Opportunity_Id__r.StageName, DMT_Line__r.Name, DMT_Line__r.Status__c, '
                     + 'Amount__c, Account.Name, CaseNumber, CurrencyIsoCode, DMT_Feature_Id__c, DMT_Passport_Sanction__c '
                + 'FROM Case '
                + 'WHERE DMT_Line__r.Line_Id__c = \'' + String.escapeSingleQuotes(lineExternalId) + '\' '
                + 'AND DMT_Feature_Id__c IN (\'' + String.escapeSingleQuotes(String.join(featuresIds, '\',\'')) + '\')';

            List<Case> allCases = (List<Case>) DMT_WithoutSharingDAO.query(queryString, 'Case');

            if (allCases == null || allCases.isEmpty()) {
                return resultByFeature;
            }

            // Group first case by feature
            Map<String, Case> firstCaseByFeature = new Map<String, Case>();
            Set<Id> caseIdsForTasks = new Set<Id>();
            for (Case c : allCases) {
                if (!firstCaseByFeature.containsKey(c.DMT_Feature_Id__c)) {
                    firstCaseByFeature.put(c.DMT_Feature_Id__c, c);
                    caseIdsForTasks.add(c.Id);
                }
            }

            // 1 bulk query for ALL tasks of ALL cases
            List<Task> allTasks = [SELECT Id, WhatId, Owner.Name, Status, LastModifiedBy.Name, DMT_Completed_Date_Time__c,
                DMT_UserClosedTask__c, DMT_UserClosedTask__r.Name, CreatedDate, CompletedDateTime,
                TOLABEL(DMT_Step_Type__c), DMT_Step_Result__c, Description, DMT_Task_Type__r.Name,
                DMT_Task_Type__r.DMT_Yes_Flag__c, DMT_Task_Type__r.DMT_No_Flag__c,
                DMT_Task_Type__r.DMT_NA_Flag__c, DMT_Committee_Label__c
                FROM Task WHERE WhatId IN :caseIdsForTasks AND RecordType.DeveloperName = 'DMT_Step_Approval'
                WITH USER_MODE ORDER BY CreatedDate DESC];

            // Group tasks by CaseId
            Map<Id, List<Task>> tasksByCaseId = new Map<Id, List<Task>>();
            for (Task t : allTasks) {
                if (!tasksByCaseId.containsKey(t.WhatId)) {
                    tasksByCaseId.put(t.WhatId, new List<Task>());
                }
                tasksByCaseId.get(t.WhatId).add(t);
            }

            // Process each feature using its first case's tasks
            for (String featureId : firstCaseByFeature.keySet()) {
                Case featureCase = firstCaseByFeature.get(featureId);
                List<Task> caseTasks = tasksByCaseId.get(featureCase.Id);
                if (caseTasks != null && !caseTasks.isEmpty()) {
                    resultByFeature.put(featureId, processTasksFromCases(caseTasks));
                } else {
                    resultByFeature.put(featureId, new List<WRAPPER_Step>());
                }
            }
        } catch (Exception e) {
            DES_Exception_Utils.logException(e, 'DMT_Case_Steps_Controller', 'getAllStepsFromFeaturesLine', 'DMT', '');
        }
        return resultByFeature;
    }

    /**
     * FIX: Bulk version for Opportunity
     */
    public static Map<String, List<WRAPPER_Step>> getAllStepsFromFeaturesOpp(List<String> featuresIds, String oppExternalId) {
        Map<String, List<WRAPPER_Step>> resultByFeature = new Map<String, List<WRAPPER_Step>>();
        try {
            String queryString = 'SELECT Id, DMT_LineOpportunity__c, opportunity_id__r.Name, Opportunity_Id__r.StageName, DMT_Line__r.Name, DMT_Line__r.Status__c, '
                     + 'Amount__c, Account.Name, CaseNumber, CurrencyIsoCode, DMT_Feature_Id__c, DMT_Passport_Sanction__c '
                + 'FROM Case '
                + 'WHERE Opportunity_Id__r.DMT_Opp_Id__c = \'' + String.escapeSingleQuotes(oppExternalId) + '\' '
                + 'AND DMT_Feature_Id__c IN (\'' + String.escapeSingleQuotes(String.join(featuresIds, '\',\'')) + '\')';

            List<Case> allCases = (List<Case>) DMT_WithoutSharingDAO.query(queryString, 'Case');

            if (allCases == null || allCases.isEmpty()) {
                return resultByFeature;
            }

            Map<String, Case> firstCaseByFeature = new Map<String, Case>();
            Set<Id> caseIdsForTasks = new Set<Id>();
            for (Case c : allCases) {
                if (!firstCaseByFeature.containsKey(c.DMT_Feature_Id__c)) {
                    firstCaseByFeature.put(c.DMT_Feature_Id__c, c);
                    caseIdsForTasks.add(c.Id);
                }
            }

            List<Task> allTasks = [SELECT Id, WhatId, Owner.Name, Status, LastModifiedBy.Name, DMT_Completed_Date_Time__c,
                DMT_UserClosedTask__c, DMT_UserClosedTask__r.Name, CreatedDate, CompletedDateTime,
                TOLABEL(DMT_Step_Type__c), DMT_Step_Result__c, Description, DMT_Task_Type__r.Name,
                DMT_Task_Type__r.DMT_Yes_Flag__c, DMT_Task_Type__r.DMT_No_Flag__c,
                DMT_Task_Type__r.DMT_NA_Flag__c, DMT_Committee_Label__c
                FROM Task WHERE WhatId IN :caseIdsForTasks AND RecordType.DeveloperName = 'DMT_Step_Approval'
                WITH USER_MODE ORDER BY CreatedDate DESC];

            Map<Id, List<Task>> tasksByCaseId = new Map<Id, List<Task>>();
            for (Task t : allTasks) {
                if (!tasksByCaseId.containsKey(t.WhatId)) {
                    tasksByCaseId.put(t.WhatId, new List<Task>());
                }
                tasksByCaseId.get(t.WhatId).add(t);
            }

            for (String featureId : firstCaseByFeature.keySet()) {
                Case featureCase = firstCaseByFeature.get(featureId);
                List<Task> caseTasks = tasksByCaseId.get(featureCase.Id);
                if (caseTasks != null && !caseTasks.isEmpty()) {
                    resultByFeature.put(featureId, processTasksFromCases(caseTasks));
                } else {
                    resultByFeature.put(featureId, new List<WRAPPER_Step>());
                }
            }
        } catch (Exception e) {
            DES_Exception_Utils.logException(e, 'DMT_Case_Steps_Controller', 'getAllStepsFromFeaturesOpp', 'DMT', '');
        }
        return resultByFeature;
    }

    @AuraEnabled(cacheable=false)
    public static List<WRAPPER_Step> getStepsFromFeatureOpp(String featureId,String oppExternalId) {
        try{
            String queryString = 'SELECT Id, DMT_LineOpportunity__c, opportunity_id__r.Name, Opportunity_Id__r.StageName, DMT_Line__r.Name, DMT_Line__r.Status__c, '
                     + 'Amount__c, Account.Name, CaseNumber, CurrencyIsoCode,DMT_Feature_Id__c, DMT_Passport_Sanction__c '
                + 'FROM Case '
                + 'WHERE Opportunity_Id__r.DMT_Opp_Id__c = \'' + String.escapeSingleQuotes(oppExternalId) + '\' '
                + 'AND DMT_Feature_Id__c = \'' + String.escapeSingleQuotes(featureId) + '\'';

            String sObjectType = 'Case';

            // Llamada al método query
            List<Case> worflowCase =(List<Case>) DMT_WithoutSharingDAO.query(queryString, sObjectType);

            /* List<Case> worflowCase = new List<Case>([
            SELECT Id, DMT_LineOpportunity__c, opportunity_id__r.Name, Opportunity_Id__r.StageName, DMT_Line__r.Name, DMT_Line__r.Status__c,
            Amount__c, Account.Name, CaseNumber, CurrencyIsoCode,DMT_Feature_Id__c FROM Case WHERE DMT_Line__r.Line_Id__c=:lineExternalId AND DMT_Feature_Id__c = :featureId LIMIT 1
            ]); */

            if(worflowCase ==null || worflowCase.isEmpty() ){
                return  new List<WRAPPER_Step>();
            }else{
                return getStepsFromCase(worflowCase[0].Id);
            }
        }catch( Exception e){
            DES_Exception_Utils.logException(e,'DMT_Case_Steps_Controller', 'getStepsFromFeature', 'DMT', '');
            throw new AuraHandledException('Error '+e);
        }
    }

    /**
     * Get Cases realated to features
     */
    @AuraEnabled(cacheable=false)
    public static List<WRAPPER_Step> getCurrentStepFromFeatures(List<String> featuresIds,String lineExternalId) {
        try{
            String queryString = 'SELECT Id, DMT_LineOpportunity__c, opportunity_id__r.Name, Opportunity_Id__r.StageName, '
                + 'DMT_Line__r.Name, DMT_Line__r.Status__c, Amount__c, Account.Name, CaseNumber, '
                     + 'CurrencyIsoCode, DMT_Feature_Id__c, DMT_Passport_Sanction__c '
                + 'FROM Case '
                + 'WHERE DMT_Line__r.Line_Id__c = \'' + String.escapeSingleQuotes(lineExternalId) + '\' '
                + 'AND DMT_Feature_Id__c IN (\'' + String.escapeSingleQuotes(String.join(featuresIds, '\',\'')) + '\')';

            String sObjectType = 'Case';

            // Llamada al método query
            List<Case> worflowCases =(List<Case>) DMT_WithoutSharingDAO.query(queryString, sObjectType);
            /* List<Case> worflowCases =[
            SELECT Id, DMT_LineOpportunity__c, opportunity_id__r.Name, Opportunity_Id__r.StageName, DMT_Line__r.Name, DMT_Line__r.Status__c,
            Amount__c, Account.Name, CaseNumber, CurrencyIsoCode,DMT_Feature_Id__c FROM Case WHERE DMT_Line__r.Line_Id__c=:lineExternalId AND DMT_Feature_Id__c IN :featuresIds
            ]; */

            if(worflowCases ==null || worflowCases.isEmpty()){
                return  new List<WRAPPER_Step>();
            }else{
                return getCurrentStepsFromCases(worflowCases);
            }
        }catch( Exception e){
            DES_Exception_Utils.logException(e,'DMT_Case_Steps_Controller', 'getCurrentStepFromFeatures', 'DMT', '');
            throw new AuraHandledException('Error '+e);
        }
    }

    /**
     * Get Cases realated to features
     */
    @AuraEnabled(cacheable=false)
    public static List<WRAPPER_Step> getCurrentStepFromFeaturesOpp(List<String> featuresIds,String oppExternalId) {
        try{
            String queryString = 'SELECT Id, DMT_LineOpportunity__c, opportunity_id__r.Name, Opportunity_Id__r.StageName, '
                + 'DMT_Line__r.Name, DMT_Line__r.Status__c, Amount__c, Account.Name, CaseNumber, '
                     + 'CurrencyIsoCode, DMT_Feature_Id__c, DMT_Passport_Sanction__c '
                + 'FROM Case '
                + 'WHERE Opportunity_Id__r.DMT_Opp_Id__c = \'' + String.escapeSingleQuotes(oppExternalId) + '\' '
                + 'AND DMT_Feature_Id__c IN (\'' + String.escapeSingleQuotes(String.join(featuresIds, '\',\'')) + '\')';

            String sObjectType = 'Case';

            // Llamada al método query
            List<Case> worflowCases =(List<Case>) DMT_WithoutSharingDAO.query(queryString, sObjectType);

            if(worflowCases ==null || worflowCases.isEmpty()){
                return  new List<WRAPPER_Step>();
            }else{
                return getCurrentStepsFromCases(worflowCases);
            }
        }catch( Exception e){
            DES_Exception_Utils.logException(e,'DMT_Case_Steps_Controller', 'getCurrentStepFromFeaturesOpp', 'DMT', '');
            throw new AuraHandledException('Error '+e);
        }
    }

    /**
     * Get the file template created with the approver view, when the task has been completed
     * TODO: IDENTIFICAR ESE PDF POR RECORDTYPE O ALGUN CAMPO
     */
    @AuraEnabled(cacheable=true)
    public static ContentDocumentLink getTaskCompletedFile(Id taskId) {
        for (ContentDocumentLink link : [
            SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.FileType, ContentDocument.ContentSize,
                   ContentDocument.LatestPublishedVersion.Is_Template_PDF__c
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :taskId
            WITH USER_MODE
        ]) {
            if (link.ContentDocument != null
                && link.ContentDocument.LatestPublishedVersion != null
                && link.ContentDocument.LatestPublishedVersion.Is_Template_PDF__c == true) {
                return link;
            }
        }
        return null;
    }


    /**
     * Get files attached to the task
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getTaskFilesWithAttachments(Id taskId) {
        List<Map<String, Object>> allFiles = new List<Map<String, Object>>();

        // ContentDocuments relacionados al task
        for (ContentDocumentLink link : [
            SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.FileType, ContentDocument.ContentSize,
                   ContentDocument.LatestPublishedVersion.Is_Template_PDF__c, ContentDocument.CreatedDate
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :taskId
            WITH USER_MODE
            ORDER BY ContentDocument.CreatedDate DESC
        ]) {
            if (link.ContentDocument != null
                && (link.ContentDocument.FileType == 'JSON' || link.ContentDocument.FileType == 'HTML')) {
                continue;
            }
            Boolean isTemplate = false;
            try {
                isTemplate = link.ContentDocument.LatestPublishedVersion.Is_Template_PDF__c;
            } catch (Exception e) {
                isTemplate = false;
                DES_Exception_Utils.logException(e,'DMT_Case_Steps_Controller', 'getTaskFilesWithAttachments', 'DMT', '');
            }

            Map<String, Object> fileMap = new Map<String, Object>{
                'type' => 'ContentDocument',
                'contentDocumentId' => link.ContentDocumentId,
                'title' => link.ContentDocument.Title,
                'fileType' => link.ContentDocument.FileType,
                'createdDate' => link.ContentDocument.CreatedDate,
                'size' => link.ContentDocument.ContentSize,
                'isTemplateView' => isTemplate
            };
            allFiles.add(fileMap);
        }

        // Attachments relacionados al task
        for (Attachment att : [SELECT Id, Name, ContentType, CreatedDate, BodyLength FROM Attachment WHERE ParentId = :taskId WITH USER_MODE]) {
            Map<String, Object> fileMap = new Map<String, Object>{
                'type' => 'Attachment',
                'contentDocumentId' => att.Id,
                'title' => att.Name,
                'fileType' => att.ContentType,
                'createdDate' => att.CreatedDate,
                'size' => att.BodyLength,
                'isTemplateView' => false
            };
            allFiles.add(fileMap);
        }
        return allFiles;
    }

    public class DMT_InputCaseWrapper {
    @InvocableVariable(required=true) public Case newCase;
    @InvocableVariable public Case oldCase;
  }

    /**
     * @description Invocable method to start the next case approval process based on closed cases. Ivocated from Flow after Case update
     * @author BBVA DMT | 15-12-2025
     * @param requests List<DMT_InputCaseWrapper> that is the input from Flow with new and old Case records
     **/
  @InvocableMethod(label='Start Next Case Approval' description='Starts the next case approval process based on closed cases' category='DMT')
  public static void startNextCaseApproval(List<DMT_InputCaseWrapper> requests){
    system.debug('****** STARTING startNextCaseApproval (invocable) *****');

    if(requests == null || requests.isEmpty()){
      return;
    }

    for(DMT_InputCaseWrapper req : requests){
      Case newToProcess = req.newCase == null ? new Case() : req.newCase;
      Case oldCaseToProcess = req.oldCase == null ? new Case() : req.oldCase;

      // Delegate actual processing to helper to keep code clear/testable
      processStartNextCaseApproval(newToProcess, oldCaseToProcess);
    }
  }

  public class DMT_CaseFeatureWrapper implements Comparable {
    public Case myCase;
    public String featureId;
    public String featureName;
    public String passportSanction;
    public String caseStatus;
    public String featureType;
    public Integer featureOrder;
    public String externalLineid;
    public String approverId;
    public String taskId;
    public List<Map<String, Object>> taskList;
    public Id lineId;

        /**
         * @description Implementation of compareTo method to allow sorting by featureOrder
         * @author BBVA DMT | 15-12-2025
         **/
    public Integer compareTo(Object compareTo) {
      DMT_CaseFeatureWrapper other = (DMT_CaseFeatureWrapper) compareTo;
      if (this.featureOrder == null && other.featureOrder == null){
        return 0;
      }
      if (this.featureOrder == null){
        return 1; // nulls last
      }
      if (other.featureOrder == null){
        return -1;
      }
      if (this.featureOrder == other.featureOrder){
        return 0;
      }
      return this.featureOrder > other.featureOrder ? 1 : -1;
    }
  }

    /**
     * @description this method process the logic to start the next case approval based on closed cases, type of feature and order. Called from Invocable method and throw queaueable to create the next case
     * @author BBVA DMT | 15-12-2025
     * @param newToProcess
     * @param oldCaseToProcess
     **/
  public static void processStartNextCaseApproval(Case newToProcess, Case oldCaseToProcess){
    system.debug('****** STARTING startNextCaseApproval *****');

    Id recordTypeCaseApproval = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Approval').getRecordTypeId();
    Map<Id,Case> mapCasesToProcess = new Map<Id,Case>();
    Set<Id> setLinesorOpportunitiesIds = new Set<Id>();

    Map<Id, DMT_PassportLineWrapper> mapWrapperByLineorOpportunityId = new Map<Id, DMT_PassportLineWrapper>();
    Map<Id,Passport__c> mapPassportRecordsByCaseId = new Map<Id,Passport__c>();
    Map<Id,Map<String,Case>> mapFeaturesCasesByLineorOpportunityID = new  Map<Id,Map<String,Case>>();
    if(newToProcess == null || oldCaseToProcess == null ){
      return;
    }

    List<Task> listTaskRelated = DMT_Case_Steps_Selector.getTasksByCase(new Set<Id>{ newToProcess.Id });

    Id lineId = newToProcess.DMT_Line__c;
    Id oppId  = newToProcess.opportunity_id__c;

    Boolean isLineContext = lineId != null && newToProcess.DMT_LineOpportunity__c != 'O';
    Boolean isOppContext  = oppId != null;

    if (!isLineContext && !isOppContext) {
      return;
    }

    Id contextId = isLineContext ? lineId : oppId;

    if(newToProcess.RecordTypeId == recordTypeCaseApproval && newToProcess.IsClosed == true && !(newToProcess.isSet(Case.DMT_Closed_By_Passport__c) && newToProcess.DMT_Closed_By_Passport__c == true) && oldCaseToProcess.IsClosed == false && newToProcess.DMT_Passport_Sanction__c != null && newToProcess.DMT_Passport_Sanction__c.equalsIgnoreCase(DMT_Constants.APPROVAL)  && !listTaskRelated.isEmpty() && listTaskRelated[0].DMT_Step_Result__c == 'Yes' ) {
      mapCasesToProcess.put(newToProcess.Id, newToProcess);
      setLinesorOpportunitiesIds.add(contextId);
    }

    if(mapCasesToProcess.isEmpty()){
      return;
    }

    List<Passport__c> listPassportRecords;

    if (isLineContext) {
      listPassportRecords = DMT_Case_Steps_Selector.getPassportsByLineIds(setLinesorOpportunitiesIds);
    } else {
      listPassportRecords = DMT_Case_Steps_Selector.getPassportsByOpportunityIds(setLinesorOpportunitiesIds);
    }

    Map<Id, Case> mapCases = new Map<Id, Case>();
    List<Case> casesList;

    if (isLineContext) {
      casesList = DMT_Case_Steps_Selector.getApprovalCasesByLineIds(setLinesorOpportunitiesIds);
    } else {
      casesList = DMT_Case_Steps_Selector.getApprovalCasesByOpportunityIds(setLinesorOpportunitiesIds);
    }

    for (Case c : casesList) {
        mapCases.put(c.Id, c);
    }

    Map<Id,List<Case>> mapCasesByContextId = new Map<Id,List<Case>>();
    for(Case c : mapCases.values()){
      Id key = isLineContext ? c.DMT_Line__c : c.opportunity_id__c;
      if(!mapCasesByContextId.containsKey(key)){
        mapCasesByContextId.put(key, new List<Case>{c});
      } else {
        mapCasesByContextId.get(key).add(c);
      }
    }

    //Sacamos mapa ID linea --> Wrapper JSON Passport
    for (Case iterationCase : mapCasesToProcess.values()) {
      for(Passport__c passportRecord : listPassportRecords){
        Id passportKey = isLineContext ? passportRecord.DMT_Line__c : passportRecord.Opportunity__c;
        Id caseKey = isLineContext ? iterationCase.DMT_Line__c : iterationCase.opportunity_id__c;
        if(passportKey == caseKey && passportRecord.DMT_Passport_Save__c != null){
          if(!mapPassportRecordsByCaseId.containsKey(iterationCase.Id)){
            mapPassportRecordsByCaseId.put(iterationCase.Id, passportRecord);
            Id key = isLineContext ? iterationCase.DMT_Line__c : iterationCase.opportunity_id__c;
            System.debug('********** Registro que falla case'+iterationCase);
            System.debug('********** Registro que falla passport '+passportRecord);
            System.debug('********** Registro que falla '+passportRecord.DMT_Passport_Save__c);
            mapWrapperByLineorOpportunityId.put(key,  DMT_PassportLineWrapper.parseLinePassport(passportRecord.DMT_Passport_Save__c));
          }
        }
      }

    }

    if(mapWrapperByLineorOpportunityId.isEmpty()){
      system.debug('****** No passport wrappers found, exiting *****');
      return;

    }

    //Ahora vamos a por approver Ids de las features approval que no estan cerradas ( caso finished)
    List<String> approversIdList = new List<String>();

    for(  Id currentContextId  :mapWrapperByLineorOpportunityId.keySet()){
      for(DMT_PassportLineWrapper.feature featureIterating :mapWrapperByLineorOpportunityId.get(currentContextId).data.features){
        if(featureIterating.passportSanction=='approval' && featureIterating.tasks != null && !featureIterating.tasks.isEmpty() && featureIterating.tasks[0].approvers != null && !featureIterating.tasks[0].approvers.isEmpty()){
          approversIdList.add(featureIterating.tasks[0]?.approvers[0]?.Id);

          for(Case caseIterating : mapCasesByContextId.get(currentContextId)){
            if(String.valueOf(caseIterating.DMT_Feature_Id__c) == String.valueOf(featureIterating.id) ){
              if(!mapFeaturesCasesByLineorOpportunityID.containsKey(currentContextId)){
                mapFeaturesCasesByLineorOpportunityID.put(currentContextId, new Map<String,Case>{featureIterating.Id => caseIterating  });
              }else{
                mapFeaturesCasesByLineorOpportunityID.get(currentContextId).put(featureIterating.Id, caseIterating);
              }
            }
          }

        }
      }
    }

    System.debug('Cuantos approevrs he detectado para features approval: '+approversIdList.size());
    List<Map<String,String>> featureTypeByApprover = new  List<Map<String,String>>();
    if(approversIdList!= null){
      //Lista de mapas con los tipos de feature (Id) por approver
      featureTypeByApprover = DMT_Passport_Handler.getFeatureTypeByApproverType(approversIdList);
    }
    Map<String, String> approverTypeMap = buildApproverTypeMap(featureTypeByApprover);

    

    /* * Ticket: CIBGLOBALD-3236
     * Removed to restore total sequentiality for Risk features.
     * if (isTriggeringCaseRisk(newToProcess, mapWrapperByLineorOpportunityId, approverTypeMap)) {
        System.debug('****** El caso disparador (' + newToProcess.Id + ') es de tipo RISK. Se detiene el proceso. *****');
        return;
    }*/

        //Se construye wrapper para encontrar las task siguiente y poder  generar el caso siguiente
        //Para eso se va a iterar feature, y para cada feature se va a identificar estado del caso, si lo hay y tipo de feature
    List<DMT_CaseFeatureWrapper> listCaseFeatureWrappers = new List<DMT_CaseFeatureWrapper>();
    for(  Id currentContextId  :mapWrapperByLineorOpportunityId.keySet()){
      for(DMT_PassportLineWrapper.feature iterateFeature :mapWrapperByLineorOpportunityId.get(currentContextId).data.features){
        if(iterateFeature.passportSanction=='approval' && iterateFeature.tasks != null && !iterateFeature.tasks.isEmpty()){
            System.debug('*Test Irene iterateFeature*'+ JSON.serializePretty(iterateFeature));
          DMT_CaseFeatureWrapper cw = new DMT_CaseFeatureWrapper();
          cw.lineId = currentContextId;
          cw.featureId = String.valueOf(iterateFeature.id);
          cw.featureName = iterateFeature.name;
          cw.passportSanction = iterateFeature.passportSanction;
          cw.featureOrder = iterateFeature.orderNumber;
          cw.externalLineid = mapWrapperByLineorOpportunityId.get(currentContextId).data.opportunityId;
          Object untyped = JSON.deserializeUntyped(JSON.serialize(iterateFeature.tasks));
          List<Map<String, Object>> taskListAsMaps = new List<Map<String, Object>>();
          if (untyped instanceof List<Object>) {
            for (Object o : (List<Object>) untyped) {
              if (o instanceof Map<String, Object>) {
                taskListAsMaps.add((Map<String, Object>) o);
              }
            }
          }
          cw.taskList = taskListAsMaps;
          cw.featureType = (iterateFeature.tasks[0].approvers != null && !iterateFeature.tasks[0].approvers.isEmpty()) ? approverTypeMap.get(iterateFeature.tasks[0].approvers[0].Id) : null;
          cw.approverId = (iterateFeature.tasks[0].approvers != null && !iterateFeature.tasks[0].approvers.isEmpty()) ? iterateFeature.tasks[0].approvers[0].Id : null;
          System.debug('**task id**'  + iterateFeature.tasks[0].id);
          cw.taskId = iterateFeature.tasks[0].id;
          cw.myCase = mapFeaturesCasesByLineorOpportunityID.get(currentContextId).containsKey( iterateFeature.Id) ? mapFeaturesCasesByLineorOpportunityID.get(currentContextId).get(iterateFeature.Id): null;
          cw.caseStatus =   cw.myCase != null ? cw.myCase.Status : null;
          System.debug('**cw.myCase'  + JSON.serializePretty(cw.myCase));

                    if(cw.myCase == null || (cw.myCase != null && cw.myCase.IsClosed == false
                            && (cw.featureType == 'Business' || cw.featureType == 'Risk')) ){
            listCaseFeatureWrappers.add(cw);
          }
        }
      }
    }

    System.debug('**Lista listCaseFeatureWrappers 2'  + JSON.serializePretty(listCaseFeatureWrappers));
    List<DMT_CaseFeatureWrapper> listBussiness = new List<DMT_CaseFeatureWrapper>();
    List<DMT_CaseFeatureWrapper> listRisk = new List<DMT_CaseFeatureWrapper>();
    List<DMT_CaseFeatureWrapper> listOther = new List<DMT_CaseFeatureWrapper>();

    //Next feature:
    if(!listCaseFeatureWrappers.isEmpty()){

      listCaseFeatureWrappers.sort();
      for(DMT_CaseFeatureWrapper feature :listCaseFeatureWrappers){
        if(feature.featureType == 'Business'){
          listBussiness.add(feature);
        } else if(feature.featureType == 'Risk'){
          listRisk.add(feature);
                } else {
                    listOther.add(feature);
        }
      }

      System.debug('*** Lista Negocio Size: ' + listBussiness.size());
      System.debug('*** Lista Riesgo Size: ' + listRisk.size());
        System.debug('*** Lista otras Features Size: ' + listOther.size());

            if (listBussiness.size() > 0) {
                DMT_CaseFeatureWrapper nextBusinessFeature = listBussiness[0];
                enqueueStartCaseQueueable(nextBusinessFeature);
        } else if(listRisk.size()>0){
            DMT_CaseFeatureWrapper nextRiskFeature = listRisk[0];
            enqueueStartCaseQueueable(nextRiskFeature);

            // Lanzamiento en paralelo de features "Other" (Financial Sponsor, Estructurado, etc.)
            // SOLO para Oportunidades; para Líneas el comportamiento se mantiene igual que antes (solo Risk)
            if (isOppContext) {
            for (DMT_CaseFeatureWrapper otherFeature : listOther) {
                enqueueStartCaseQueueable(otherFeature);
            }
            }
        }
    }else if (isOppContext) {
        moveStatusToReadyToClose(contextId);
    }
  }

    private static void enqueueStartCaseQueueable(DMT_CaseFeatureWrapper feature) {
        if (feature == null || Limits.getQueueableJobs() >= Limits.getLimitQueueableJobs()) {
            System.debug(LoggingLevel.ERROR, 'Unable to enqueue approval feature: Queueable limit reached.');
            return;
    }

        System.enqueueJob(new StartCaseQueueable(
            feature.externalLineid,
            feature.approverId,
            feature.taskId,
            JSON.serialize(feature.taskList),
            feature.featureId,
            feature.featureName,
            '',
            feature.passportSanction
        ));
    }

    public static void startFirstBusinessApprovalFeature(Id contextId) {
    if (contextId == null) return;
    System.enqueueJob(new StartFirstBusinessApprovalQueueable(contextId));
}

    private static void processFirstBusinessApprovalFeature(Id contextId) {
        if (contextId == null) return;

                List<Passport__c> listPassportRecords = DMT_Case_Steps_Selector.getPassportsByOpportunityIds(new Set<Id>{ contextId });

        System.debug('###IRENE### listPassportRecords.size()=' + listPassportRecords.size());

        if (listPassportRecords.isEmpty() || listPassportRecords[0].DMT_Passport_Save__c == null) return;

        DMT_PassportLineWrapper wrapper = DMT_PassportLineWrapper.parseLinePassport(listPassportRecords[0].DMT_Passport_Save__c);
        if (wrapper?.data?.features == null) return;

        List<Case> existingCases = DMT_Case_Steps_Selector.getApprovalCasesByOpportunityIds(new Set<Id>{ contextId });

        if (!existingCases.isEmpty()) return;

        List<String> approversIdList = new List<String>();
        for (DMT_PassportLineWrapper.feature f : wrapper.data.features) {
            if (f.passportSanction == 'approval' && f.tasks != null && !f.tasks.isEmpty()
                && f.tasks[0].approvers != null && !f.tasks[0].approvers.isEmpty()) {
                approversIdList.add(f.tasks[0].approvers[0].Id);
            }
        }
        Map<String, String> approverTypeMap = buildApproverTypeMap(
            DMT_Passport_Handler.getFeatureTypeByApproverType(approversIdList)
        );

        // CAMBIO: ya no filtramos solo Business aquí; recogemos ambos tipos y decidimos después,
        // igual que hace processStartNextCaseApproval
        List<DMT_CaseFeatureWrapper> pending = new List<DMT_CaseFeatureWrapper>();
        for (DMT_PassportLineWrapper.feature f : wrapper.data.features) {
            if (f.passportSanction != 'approval' || f.tasks == null || f.tasks.isEmpty()) continue;

            String approverId = (f.tasks[0].approvers != null && !f.tasks[0].approvers.isEmpty()) ? f.tasks[0].approvers[0].Id : null;
            if (approverId == null) continue;

            String featureType = approverTypeMap.get(approverId);
            if (featureType != 'Business' && featureType != 'Risk') continue;

            DMT_CaseFeatureWrapper cw = new DMT_CaseFeatureWrapper();
            cw.featureId = String.valueOf(f.id);
            cw.featureName = f.name;
            cw.passportSanction = f.passportSanction;
            cw.featureOrder = f.orderNumber;
            cw.externalLineid = wrapper.data.opportunityId;
            cw.taskId = f.tasks[0].id;
            cw.approverId = approverId;
            cw.featureType = featureType;

            Object untyped = JSON.deserializeUntyped(JSON.serialize(f.tasks));
            List<Map<String, Object>> taskListAsMaps = new List<Map<String, Object>>();
            if (untyped instanceof List<Object>) {
                for (Object o : (List<Object>) untyped) {
                    if (o instanceof Map<String, Object>) taskListAsMaps.add((Map<String, Object>) o);
                }
            }
            cw.taskList = taskListAsMaps;
            pending.add(cw);
        }

        if (pending.isEmpty()) return;
        pending.sort();

        // CAMBIO: separar por tipo y priorizar Business, igual que processStartNextCaseApproval
        List<DMT_CaseFeatureWrapper> businessPending = new List<DMT_CaseFeatureWrapper>();
        List<DMT_CaseFeatureWrapper> riskPending = new List<DMT_CaseFeatureWrapper>();
        for (DMT_CaseFeatureWrapper cw : pending) {
            if (cw.featureType == 'Business') {
                businessPending.add(cw);
            } else if (cw.featureType == 'Risk') {
                riskPending.add(cw);
            }
        }

        DMT_CaseFeatureWrapper first = !businessPending.isEmpty() ? businessPending[0]
            : (!riskPending.isEmpty() ? riskPending[0] : null);
        if (first == null) return;

        List<Map<String, Object>> taskListCopy = first.taskList;
        if (!taskListCopy.isEmpty()) taskListCopy.remove(0);

        System.enqueueJob(new StartCaseQueueable(
            first.externalLineid, first.approverId, first.taskId,
            JSON.serialize(taskListCopy), first.featureId, first.featureName, '', first.passportSanction
        ));
    }

    public class StartFirstBusinessApprovalQueueable implements Queueable {
        private final Id contextId;

        public StartFirstBusinessApprovalQueueable(Id contextId) {
            this.contextId = contextId;
        }

        public void execute(QueueableContext context) {
            processFirstBusinessApprovalFeature(contextId);
        }
    }

  @TestVisible
    private static void moveStatusToReadyToClose(Id contextId) {
        if (contextId == null) {
            return;
        }

        System.debug('Queries usadas before oppToUpdate: ' + Limits.getQueries());

            List<Passport__c> passports = DMT_Case_Steps_Selector.getPassportsByOpportunityIds(new Set<Id>{ contextId });

            if (!passports.isEmpty() && passports[0].Opportunity__r.StageName == DMT_Constants.APPROVAL) {
                Opportunity oppToUpdate = new Opportunity(
                    Id = contextId,
                    StageName = DMT_Constants.READYTOCLOSE
                );
                update oppToUpdate;
            }

        System.debug('Queries usadas after oppToUpdate: ' + Limits.getQueries());
    }

  /**
   * @description Build a map of approverId -> featureType from a list of maps
   * @author BBVA DMT | 12-12-2025
   * @param featureTypeByApprover
   * @return Map<String, String>
   **/
  @TestVisible
  private static Map<String, String> buildApproverTypeMap(List<Map<String, String>> featureTypeByApprover) {
    Map<String, String> result = new Map<String, String>();
    if (featureTypeByApprover == null || featureTypeByApprover.isEmpty()){
      return result;
    }
    for (Map<String, String> m : featureTypeByApprover) {
      if (m == null){
        continue;
      }
      String approverId = null;
      if (m.containsKey('approverId')){
        approverId = m.get('approverId');
      }else if (m.containsKey('approver')){
        approverId = m.get('approver');
      }else if (m.containsKey('id')){
        approverId = m.get('id');
      }

      String featureType = null;
      if (m.containsKey('featureType')){
        featureType = m.get('featureType');
      }else if (m.containsKey('type')){
        featureType = m.get('type');
      }else {
        // fallback to first value in the map
        for (String v : m.values()) { featureType = v; break; }
      }

      if (approverId != null && featureType != null) {
        result.put(approverId, featureType);
      }
    }
    return result;
  }

  /**
 * Verifica si la feature asociada al caso que dispara el proceso es de tipo 'Risk'
 */
/*
* Ticket: CIBGLOBALD-3236
     * Removed to restore total sequentiality for Risk features.
    private static Boolean isTriggeringCaseRisk(Case newToProcess, Map<Id, DMT_PassportLineWrapper> mapWrapper, Map<String, String> approverTypeMap) {
    String triggerFeatureId = String.valueOf(newToProcess.DMT_Feature_Id__c);
    if (String.isBlank(triggerFeatureId)){
      return false;
    }
    for (DMT_PassportLineWrapper wrapper : mapWrapper.values()) {
        if (wrapper.data == null || wrapper.data.features == null){
          continue;
        }
        for (DMT_PassportLineWrapper.feature feature : wrapper.data.features) {
            if (String.valueOf(feature.id) == triggerFeatureId) {
                if (feature.tasks != null && !feature.tasks.isEmpty() &&
                    feature.tasks[0].approvers != null && !feature.tasks[0].approvers.isEmpty()) {
                    String approverId = feature.tasks[0].approvers[0].Id;
                    String type = approverTypeMap.get(approverId);
                    if (type != null && type.equalsIgnoreCase('Risk')) {
                        return true;
                    }
                }
            }
        }
    }
    return false;
} */

  public class StartCaseQueueable implements Queueable, Database.AllowsCallouts {
    private final String externalLineid;
    private final String approverId;
    private final String taskId;
    private final String taskListJson;
    private final String featureId;
    private final String featureName;
    private final String comment;
    private final String passportSanction;

        /**
         * @description Constructor for StartCaseQueueable class
         * @author BBVA DMT | 15-12-2025
         * @param externalLineid externalId from Opportunity/Line
         * @param approverId id of the approver(externalId)
         * @param taskId
         * @param taskListJson next task list in JSON format
         * @param featureId featureId from passport
         * @param featureName feature names from passport
         * @param comment coment to add to the case, in this automatic case it's empty
         * @param passportSanction stage of the feature in passport (passport or approval)
         **/
    public StartCaseQueueable(String externalLineid, String approverId, String taskId, String taskListJson, String featureId, String featureName, String comment, String passportSanction) {
      this.externalLineid = externalLineid;
      this.approverId = approverId;
      this.taskId = taskId;
      this.taskListJson = taskListJson;
      this.featureId = featureId;
      this.featureName = featureName;
      this.comment = comment;
      this.passportSanction = passportSanction;
    }

        /**
         * @description Execute method for StartCaseQueueable class, calls DMT_Passport_Handler.startCase method to start the case creation process
         * @author BBVA DMT | 15-12-2025
         * @param ctx
         **/
    public void execute(QueueableContext ctx) {

        Object raw = JSON.deserializeUntyped(this.taskListJson);
        List<Map<String, Object>> taskList = new List<Map<String, Object>>();
        if (raw instanceof List<Object>) {
          for (Object o : (List<Object>) raw) {
            taskList.add((Map<String, Object>) o);
          }
        }

        if (!taskList.isEmpty()) {
            taskList.remove(0);
        }

        System.debug('*** QUEUEABLE PRE-EXECUTE: Trying to create Case for Feature: ' + featureId);

        // Llamada a startCase ya en ejecución asíncrona
        Map<String, Object> queueableResult = DMT_Passport_Handler.startCase(externalLineid, approverId, taskId, taskList, featureId, featureName, comment, passportSanction);

        System.debug('*** QUEUEABLE POST-EXECUTE RESULT: ' + JSON.serialize(queueableResult));

        if (queueableResult.get('success') == false || queueableResult.get('success') == 'false') {
            System.debug(LoggingLevel.ERROR, '*** QUEUEABLE SILENT FAILURE! Reason: ' + queueableResult.get('message'));
        }
    }
  }

  /**
   * @description Validates if the DMT Line meets approval criteria based on Passport JSON data and Case status.
   * @param lineId The ID of the DMT_Line__c record to validate.
   * @return Boolean True if validation passes, False otherwise.
   */
  @AuraEnabled
  public static Boolean checkApprovalValidation(Id lineId) {
      try {
          if (lineId == null) return false;

          // 1. Retrieve Passport data associated with the Line
          List<Passport__c> passportList = [SELECT DMT_Passport_Save__c FROM Passport__c WHERE DMT_Line__c = :lineId WITH USER_MODE LIMIT 1];

          if (passportList.isEmpty() || String.isBlank(passportList[0].DMT_Passport_Save__c)) {
              return false;
          }

          // 2. Parse JSON to identify required Approval Features
          Set<String> approvalFeatureSet = new Set<String>();
          Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(passportList[0].DMT_Passport_Save__c);
          Map<String, Object> dataMap = (Map<String, Object>) root.get('data');

          if (dataMap != null && dataMap.containsKey('features')) {
              List<Object> rawFeatures = (List<Object>) dataMap.get('features');
              for (Object featureObj : rawFeatures) {
                  Map<String, Object> featureData = (Map<String, Object>) featureObj;
                  String sanction = String.valueOf(featureData.get('passportSanction'));
                  Object featId = featureData.get('id');

                  if (featId != null && sanction != null && sanction.equalsIgnoreCase(DMT_Constants.APPROVAL)) {
                      approvalFeatureSet.add(String.valueOf(featId));
                  }
              }
          }

          // 3. Retrieve existing Finished Approval Cases
          List<Case> approvalCases = [SELECT Id, DMT_Feature_Id__c FROM Case WHERE DMT_Line__c = :lineId AND Status = :DMT_Constants.FINISHED AND DMT_Passport_Sanction__c = 'approval' WITH USER_MODE];

          Set<String> approvalCasesSet = new Set<String>();
          for (Case c : approvalCases) {
              if (c.DMT_Feature_Id__c != null) {
                  approvalCasesSet.add(c.DMT_Feature_Id__c);
              }
          }

          // 4. Comparison Logic: Feature Sets must match
          if (approvalFeatureSet.isEmpty()) {
              return true;
          }

          if (!approvalCasesSet.equals(approvalFeatureSet)) {
              return false;
          }

          // 5. Deep Step Validation via existing Controller logic
          // We assume getCurrentStepsFromCases is a static method in this same class
          List<WRAPPER_Step> stepGroups = getCurrentStepsFromCases(approvalCases);

          if (stepGroups.isEmpty()) {
              return false;
          }

          for (WRAPPER_Step step : stepGroups[0].subitems) {
              if (step.rawresult != 'Yes') {
                  return false; // Early exit if any step is not 'Yes'
              }
          }

          return true;

      } catch (Exception e) {
          // Log error and return false to fail gracefully in the UI/Trigger
          System.debug(LoggingLevel.ERROR, 'Error in checkApprovalValidation: ' + e.getMessage());
          return false;
      }
  }

    @AuraEnabled
    public static void updateTask(Id taskId, Map<String, Object> fieldsToUpdate) {
        try {
            String jsonString = JSON.serialize(fieldsToUpdate);
            Task taskToUpdate = (Task) JSON.deserialize(jsonString, Task.class);
            taskToUpdate.Id = taskId;
            update taskToUpdate;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class WRAPPER_Step {
        @AuraEnabled
        public Integer id;
        @AuraEnabled
        public String approver;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public WRAPPER_URL step;
        @AuraEnabled
        public String lineOrOpportunity;
        @AuraEnabled
        public WRAPPER_URL oppLineName;
        @AuraEnabled
        public String lineDetails;
        @AuraEnabled
        public String client;
        @AuraEnabled
        public String startDate;
        @AuraEnabled
        public String endDate;
        @AuraEnabled
        public String taskDetails;
        @AuraEnabled
        public String user;
        @AuraEnabled
        public Boolean sameAsSubItems;
        @AuraEnabled
        public Boolean itemKeyAsLink;
        @AuraEnabled
        public String itemKey;
        @AuraEnabled
        public String itemLabel;
        @AuraEnabled
        public String result;
        @AuraEnabled
        public String rawresult;
        @AuraEnabled
        public String taskId;
        @AuraEnabled
        public String caseId;
        @AuraEnabled
        public String lineOpportunityDateToProposal;
        @AuraEnabled
        public String description;
        @AuraEnabled
        public String featureId;
        @AuraEnabled
        public String featureName;
        @AuraEnabled
        public String featureType;
        @AuraEnabled
        public String lineOppStatus;
        @AuraEnabled
        public String caseStatus;
        @AuraEnabled
        public Integer taskSize;
        @AuraEnabled
        public List<WRAPPER_Step> subitems;
        @AuraEnabled
        public String descriptionCase;
        @AuraEnabled
        public String committeeLabel;
        //Added fields of OpportunityId and LineId, also added the group Client Name
        @AuraEnabled
        public String lineOppId;
        @AuraEnabled
        public String groupClientName;

    }

    public class WRAPPER_URL {
        @AuraEnabled
        public String urlLabel;
        @AuraEnabled
        public String urlValue;
    }
}