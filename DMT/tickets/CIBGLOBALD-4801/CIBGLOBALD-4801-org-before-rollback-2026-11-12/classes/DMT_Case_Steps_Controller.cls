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

        List<WRAPPER_Step> fullData = processTasksFromCases(tasks);

        // --- "Closed Tasks" section ---
        // Cases where the current user completed a task but is no longer the active assignee
        Set<Id> pendingCaseIds = new Set<Id>(casesMap.keySet());
        List<Task> userCompletedTasks = DMT_Case_Steps_Selector.getCompletedTasksByUser(UserInfo.getUserId(), pendingCaseIds);

        if (!userCompletedTasks.isEmpty()) {
            Set<Id> completedTaskCaseIds = new Set<Id>();
            for (Task t : userCompletedTasks) {
                completedTaskCaseIds.add(t.WhatId);
            }

            // Get open (non-Finished) Approval cases from those IDs
            List<Case> openCases = DMT_Case_Steps_Selector.getOpenApprovalCasesByIds(completedTaskCaseIds);

            // Exclude cases whose Line/Opp is already closed
            Set<Id> openValidCaseIds = new Set<Id>();
            for (Case c : openCases) {
                Boolean isLineOppClosed = false;
                if (c.DMT_LineOpportunity__c != null) {
                    if (c.DMT_LineOpportunity__c.equalsIgnoreCase('L') && c.DMT_Line__r != null
                            && c.DMT_Line__r.Status__c != null && c.DMT_Line__r.Status__c.contains('Closed')) {
                        isLineOppClosed = true;
                    } else if (c.DMT_LineOpportunity__c.equalsIgnoreCase('O') && c.Opportunity_Id__r != null
                            && c.Opportunity_Id__r.StageName != null && c.Opportunity_Id__r.StageName.contains('Closed')) {
                        isLineOppClosed = true;
                    } else if (c.DMT_LineOpportunity__c.equalsIgnoreCase('L') && c.DMT_Line__r != null
                            && c.DMT_Line__r.RecordType != null
                            && (c.DMT_Line__r.RecordType.DeveloperName == 'TreasurySettlement' || c.DMT_Line__r.RecordType.DeveloperName == 'OtherProducts')
                            && c.DMT_Line__r.Booking_Geography__c != null && c.DMT_Line__r.Booking_Geography__c != 'PE'
                            && c.DMT_Line__r.Status__c != null && c.DMT_Line__r.Status__c == DMT_Constants.READYTOCLOSE) {
                        isLineOppClosed = true;
                    }
                }
                if (!isLineOppClosed) {
                    openValidCaseIds.add(c.Id);
                }
            }

            if (!openValidCaseIds.isEmpty()) {
                Map<Id, Task> closedTasksTaskMap = DMT_Case_Steps_Selector.getTasksByNotInTaskMap(openValidCaseIds, new Set<Id>());
                List<Task> closedTasksList = DMT_Case_Steps_Selector.getTasksById(closedTasksTaskMap.keySet());

                if (!closedTasksList.isEmpty()) {
                    List<WRAPPER_Step> rawClosedSteps = processTasksFromCases(closedTasksList);

                    // Collect only flat case-level steps (not the parentStep groups like 'Finished'/'Closed')
                    List<WRAPPER_Step> closedTaskItems = new List<WRAPPER_Step>();
                    for (WRAPPER_Step s : rawClosedSteps) {
                        if (s.itemKey != 'Finished' && s.itemKey != 'Closed' && s.itemKey != 'ClosedTasks') {
                            closedTaskItems.add(s);
                        }
                    }

                    if (!closedTaskItems.isEmpty()) {
                        WRAPPER_Step parentStepClosedTasks = new WRAPPER_Step();
                        parentStepClosedTasks.itemLabel = 'Closed Tasks';
                        parentStepClosedTasks.itemKey = 'ClosedTasks';
                        parentStepClosedTasks.itemKeyAsLink = false;
                        parentStepClosedTasks.subitems = closedTaskItems;
                        fullData.add(parentStepClosedTasks);
                    }
                }
            }
        }

        return fullData;

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
        parentStepFinished.itemLabel = 'Closed Features';
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
                //substep.lineOrOpportunity = cases.get(caseId).DMT_LineOpportunity__c; // CIBGLOBAL-4628 cambia por tipoFuncOperacionProd
                if(cases.get(caseId).DMT_LineOpportunity__c == 'O'){
                     substep.tipoFuncOperacionProd = cases.get(caseId).opportunity_id__r.DMT_Product_Area__c;

                }else if(cases.get(caseId).DMT_LineOpportunity__c == 'L'){
                    if(cases.get(caseId).DMT_Line__r.RecordType.DeveloperName == 'TreasurySettlement'){
                            substep.tipoFuncOperacionProd = DMT_Constants.LINE_RT_TSLINE;

                    }else if(cases.get(caseId).DMT_Line__r.RecordType.DeveloperName == 'OtherProducts'){
                            substep.tipoFuncOperacionProd = DMT_Constants.LINE_RT_OTHERLINE;
                    }
                }

                substep.oppLineName = new WRAPPER_Url();
                substep.oppLineName.urlLabel = cases.get(caseId).DMT_LineOpportunity__c == 'O' ? cases.get(caseId).opportunity_id__r.Name : cases.get(caseId).DMT_Line__r.Name;
                substep.description = cases.get(caseId).description;
                substep.oppLineName.urlValue = cases.get(caseId).DMT_LineOpportunity__c == 'O' ? '/' + cases.get(caseId).opportunity_id__c : '/' + cases.get(caseId).DMT_Line__c;
                substep.lineDetails = cases.get(caseId).DMT_Line__r != null ? String.valueOf(cases.get(caseId).DMT_Line__r.Line_Details__c) : '';
                substep.client = cases.get(caseId).DMT_LineOpportunity__c == 'O' ? cases.get(caseId).opportunity_id__r.DMT_Main_Holder_Name__c : cases.get(caseId).Account?.Name;
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
                substep.groupClientName = cases.get(caseId).DMT_LineOpportunity__c == 'O' ? cases.get(caseId).opportunity_id__r.DMT_Group_Name__c : (cases.get(caseId).Account.DES_Client_Type__c == 'CIB Group' ? cases.get(caseId).Account.Name : cases.get(caseId).Account.DES_Main_Parent__r.Name);
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
    public String autoWorkflowRequest;

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
  // CIBGLOBALD-4801 - Enhancement to existing process: body reorganised for one record per call (Case checks before any query, Passport and Cases loaded once and reused by moveStatusToReadyToClose, newest Case per feature, DMT_Constants, Spanish debug lines removed); the approval sequencing (Business, then Risk with the other approval features in parallel for Opportunities) is unchanged
  public static void processStartNextCaseApproval(Case newToProcess, Case oldCaseToProcess){
    if (newToProcess == null || oldCaseToProcess == null) {
      return;
    }

    Id lineId = newToProcess.DMT_Line__c;
    Id oppId  = newToProcess.opportunity_id__c;

    Boolean isLineContext = lineId != null && newToProcess.DMT_LineOpportunity__c != 'O';
    Boolean isOppContext  = oppId != null;

    if (!isLineContext && !isOppContext) {
      return;
    }

    Id contextId = isLineContext ? lineId : oppId;

    // CIBGLOBALD-4801 - Enhancement to existing process: the Case checks run before any query, so a Case save that does not close an approval Case costs no SOQL (was 1 Task query on every save through Case_After_Trigger_Flow)
    Id recordTypeCaseApproval = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(DMT_Constants.CASE_RT_APPROVAL).getRecordTypeId();
    Boolean closesApprovalCase = newToProcess.RecordTypeId == recordTypeCaseApproval && newToProcess.IsClosed == true
      && !(newToProcess.isSet(Case.DMT_Closed_By_Passport__c) && newToProcess.DMT_Closed_By_Passport__c == true)
      && oldCaseToProcess.IsClosed == false
      && newToProcess.DMT_Passport_Sanction__c != null && newToProcess.DMT_Passport_Sanction__c.equalsIgnoreCase(DMT_Constants.APPROVAL);
    if (!closesApprovalCase) {
      return;
    }

    Set<Id> contextIds = new Set<Id>{ contextId };
    List<Case> contextCases = isLineContext
      ? DMT_Case_Steps_Selector.getApprovalCasesByLineIds(contextIds)
      : DMT_Case_Steps_Selector.getApprovalCasesByOpportunityIds(contextIds);

    // CIBGLOBALD-4801 - Enhancement to existing process: the latest step Task of the closed Case comes with the Case query (selector subquery) instead of a separate Task query
    Case closedCase = null;
    for (Case contextCase : contextCases) {
      if (contextCase.Id == newToProcess.Id) {
        closedCase = contextCase;
      }
    }
    if (closedCase == null || closedCase.Tasks.isEmpty() || closedCase.Tasks[0].DMT_Step_Result__c != 'Yes') {
      return;
    }

    // CIBGLOBALD-4801 - Enhancement to existing process: one record per call, so the newest Passport with JSON is kept directly (no per-Case maps)
    List<Passport__c> listPassportRecords = isLineContext
      ? DMT_Case_Steps_Selector.getPassportsByLineIds(contextIds)
      : DMT_Case_Steps_Selector.getPassportsByOpportunityIds(contextIds);
    Passport__c contextPassport = null;
    for (Passport__c passportRecord : listPassportRecords) {
      if (contextPassport == null && passportRecord.DMT_Passport_Save__c != null) {
        contextPassport = passportRecord;
      }
    }
    if (contextPassport == null) {
      return;
    }
    DMT_PassportLineWrapper passportWrapper = DMT_PassportLineWrapper.parseLinePassport(contextPassport.DMT_Passport_Save__c);
    if (passportWrapper?.data?.features == null) {
      return;
    }

    Boolean isAutoWorkflowCase = isAutoWorkflowCaseForContext(isOppContext && !isLineContext, passportWrapper, newToProcess);

    // CIBGLOBALD-4801 - Enhancement to existing process: newest Case per feature (the selector returns newest first)
    Map<String, Case> caseByFeatureId = new Map<String, Case>();
    for (Case contextCase : contextCases) {
      if (contextCase.DMT_Feature_Id__c != null && !caseByFeatureId.containsKey(contextCase.DMT_Feature_Id__c)) {
        caseByFeatureId.put(contextCase.DMT_Feature_Id__c, contextCase);
      }
    }

    // Approver Ids of the approval features, to know which ones are Business and which Risk
    List<String> approversIdList = new List<String>();
    for (DMT_PassportLineWrapper.feature featureIterating : passportWrapper.data.features) {
      Boolean isAutoWorkflowFeature = 'Y'.equalsIgnoreCase(featureIterating.autoWorkflowRequest);
      if (featureIterating.passportSanction == APPROVAL_SANCTION && featureIterating.tasks != null && !featureIterating.tasks.isEmpty() // CIBGLOBALD-4801
          && (!isAutoWorkflowCase || isAutoWorkflowFeature)
          && featureIterating.tasks[0].approvers != null && !featureIterating.tasks[0].approvers.isEmpty()) {
        approversIdList.add(featureIterating.tasks[0].approvers[0].Id);
      }
    }
    Map<String, String> approverTypeMap = buildApproverTypeMap(DMT_Passport_Handler.getFeatureTypeByApproverType(approversIdList));

    // One wrapper per approval feature with tasks: its Case (if any), type and order, to pick the next Case to start
    List<DMT_CaseFeatureWrapper> listCaseFeatureWrappers = new List<DMT_CaseFeatureWrapper>();
    Boolean hasPendingAutoWorkflowFeature = false;
    Boolean hasPendingManualFeature = false;
    for (DMT_PassportLineWrapper.feature iterateFeature : passportWrapper.data.features) {
      if (iterateFeature.passportSanction != APPROVAL_SANCTION || iterateFeature.tasks == null || iterateFeature.tasks.isEmpty()) { // CIBGLOBALD-4801
        continue;
      }
      DMT_CaseFeatureWrapper cw = new DMT_CaseFeatureWrapper();
      cw.lineId = contextId;
      cw.featureId = String.valueOf(iterateFeature.id);
      cw.featureName = iterateFeature.name;
      cw.passportSanction = iterateFeature.passportSanction;
      cw.autoWorkflowRequest = iterateFeature.autoWorkflowRequest;
      cw.featureOrder = iterateFeature.orderNumber;
      cw.externalLineid = passportWrapper.data.opportunityId;
      cw.taskList = toTaskMaps(iterateFeature.tasks);
      Boolean hasApprover = iterateFeature.tasks[0].approvers != null && !iterateFeature.tasks[0].approvers.isEmpty();
      cw.featureType = hasApprover ? approverTypeMap.get(iterateFeature.tasks[0].approvers[0].Id) : null;
      cw.approverId = hasApprover ? iterateFeature.tasks[0].approvers[0].Id : null;
      cw.taskId = iterateFeature.tasks[0].id;
      cw.myCase = caseByFeatureId.get(cw.featureId);
      cw.caseStatus = cw.myCase != null ? cw.myCase.Status : null;

      if (isAutoWorkflowCase) {
        Boolean isAutoWorkflowFeature = 'Y'.equalsIgnoreCase(iterateFeature.autoWorkflowRequest);
        if (cw.myCase == null) {
          if (isAutoWorkflowFeature) {
            listCaseFeatureWrappers.add(cw);
            hasPendingAutoWorkflowFeature = true;
          } else {
            hasPendingManualFeature = true;
          }
        } else if (!cw.myCase.IsClosed) {
          if (isAutoWorkflowFeature) {
            hasPendingAutoWorkflowFeature = true;
          } else {
            hasPendingManualFeature = true;
          }
        }
      } else if (cw.myCase == null || (!cw.myCase.IsClosed
          && (cw.featureType == DMT_Constants.APPROVER_TYPE_BUSINESS || cw.featureType == DMT_Constants.APPROVER_TYPE_RISK))) { // CIBGLOBALD-4801
        listCaseFeatureWrappers.add(cw);
      }
    }

    if (isAutoWorkflowCase) {
      if (isOppContext && !hasPendingAutoWorkflowFeature && !hasPendingManualFeature) {
        moveStatusToReadyToClose(contextPassport, contextCases); // CIBGLOBALD-4801
      }
      return;
    }

    if (listCaseFeatureWrappers.isEmpty()) {
      if (isOppContext) {
        moveStatusToReadyToClose(contextPassport, contextCases); // CIBGLOBALD-4801
      }
      return;
    }

    // Next feature: Business first; then Risk, with the other approval features in parallel (Opportunities only)
    List<DMT_CaseFeatureWrapper> listBusiness = new List<DMT_CaseFeatureWrapper>(); // CIBGLOBALD-4801
    List<DMT_CaseFeatureWrapper> listRisk = new List<DMT_CaseFeatureWrapper>();
    List<DMT_CaseFeatureWrapper> listOther = new List<DMT_CaseFeatureWrapper>();
    listCaseFeatureWrappers.sort();
    for (DMT_CaseFeatureWrapper feature : listCaseFeatureWrappers) {
      if (feature.featureType == DMT_Constants.APPROVER_TYPE_BUSINESS) { // CIBGLOBALD-4801
        listBusiness.add(feature);
      } else if (feature.featureType == DMT_Constants.APPROVER_TYPE_RISK) { // CIBGLOBALD-4801
        listRisk.add(feature);
      } else {
        listOther.add(feature);
      }
    }

    if (!listBusiness.isEmpty()) {
      enqueueStartCaseQueueable(listBusiness[0]);
    } else if (!listRisk.isEmpty()) {
      enqueueStartCaseQueueable(listRisk[0]);
      // Other approval features (Financial Sponsor, Structured...) start in parallel with Risk, only for Opportunities
      if (isOppContext) {
        for (DMT_CaseFeatureWrapper otherFeature : listOther) {
          enqueueStartCaseQueueable(otherFeature);
        }
      }
    }
  }

  // CIBGLOBALD-4801 - Enhancement to existing process: passportSanction value of the approval features in the Passport JSON
  private static final String APPROVAL_SANCTION = 'approval';

  // CIBGLOBALD-4801 - Enhancement to existing process: Passport tasks as untyped maps (the shape StartCaseQueueable expects), shared instead of repeated inline
  private static List<Map<String, Object>> toTaskMaps(Object tasks) {
    List<Map<String, Object>> taskListAsMaps = new List<Map<String, Object>>();
    Object untyped = JSON.deserializeUntyped(JSON.serialize(tasks));
    if (untyped instanceof List<Object>) {
      for (Object taskObject : (List<Object>) untyped) {
        if (taskObject instanceof Map<String, Object>) {
          taskListAsMaps.add((Map<String, Object>) taskObject);
        }
      }
    }
    return taskListAsMaps;
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

        List<Case> existingApprovalPhaseCases = new List<Case>();
        for (Case c : existingCases) {
            if (c.DMT_Passport_Sanction__c == 'approval') existingApprovalPhaseCases.add(c);
        }
        if (!existingApprovalPhaseCases.isEmpty()) return;

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

    public static void enqueueAutoWorkflowCases(Map<Id, String> stageByLineId, Boolean ignored) {
        enqueueAutoWorkflowCasesForContext(stageByLineId, false);
    }

    public static void enqueueAutoWorkflowCasesForOpportunities(Map<Id, String> stageByOpportunityId) {
        enqueueAutoWorkflowCasesForContext(stageByOpportunityId, true);
    }

    private static void enqueueAutoWorkflowCasesForContext(Map<Id, String> stageByContextId, Boolean isOpportunity) {
        if (stageByContextId == null || stageByContextId.isEmpty()) {
            return;
        }

        Set<Id> eligibleContextIds = new Set<Id>();
        for (Id contextId : stageByContextId.keySet()) {
            String stage = stageByContextId.get(contextId);
            if (contextId != null && (stage == DMT_Constants.PROPOSAL
                || stage == DMT_Constants.APPROVAL
                || stage == DMT_Constants.READYTOCLOSE)) {
                eligibleContextIds.add(contextId);
            }
        }
        if (eligibleContextIds.isEmpty()) {
            return;
        }

        Map<Id, Passport__c> passportByContextId = new Map<Id, Passport__c>();
        List<Passport__c> passports = isOpportunity
            ? DMT_Case_Steps_Selector.getPassportsByOpportunityIds(eligibleContextIds)
            : DMT_Case_Steps_Selector.getPassportsByLineIds(eligibleContextIds);
        for (Passport__c passport : passports) {
            Id contextId = isOpportunity ? passport.Opportunity__c : passport.DMT_Line__c;
            if (!passportByContextId.containsKey(contextId)) {
                passportByContextId.put(contextId, passport);
            }
        }

        Map<Id, Set<String>> startedFeaturesByContextId = new Map<Id, Set<String>>();
        List<Case> approvalCases = isOpportunity
            ? DMT_Case_Steps_Selector.getApprovalCasesByOpportunityIds(eligibleContextIds)
            : DMT_Case_Steps_Selector.getApprovalCasesByLineIds(eligibleContextIds);
        for (Case approvalCase : approvalCases) {
            Id contextId = isOpportunity ? approvalCase.opportunity_id__c : approvalCase.DMT_Line__c;
            if (contextId == null || String.isBlank(approvalCase.DMT_Feature_Id__c)) {
                continue;
            }
            if (!startedFeaturesByContextId.containsKey(contextId)) {
                startedFeaturesByContextId.put(contextId, new Set<String>());
            }
            startedFeaturesByContextId.get(contextId).add(approvalCase.DMT_Feature_Id__c);
        }

        for (Id contextId : eligibleContextIds) {
            Passport__c passport = passportByContextId.get(contextId);
            if (passport == null || String.isBlank(passport.DMT_Passport_Save__c)) {
                continue;
            }

            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(passport.DMT_Passport_Save__c);
            Map<String, Object> data = (Map<String, Object>) root.get('data');
            if (data == null || !(data.get('features') instanceof List<Object>)) {
                continue;
            }

            Set<String> startedFeatureIds = startedFeaturesByContextId.containsKey(contextId)
                ? startedFeaturesByContextId.get(contextId)
                : new Set<String>();
            String expectedSanction = autoWorkflowSanctionForStage(stageByContextId.get(contextId));
            List<DMT_CaseFeatureWrapper> eligibleFeatures = new List<DMT_CaseFeatureWrapper>();
            for (Object rawFeature : (List<Object>) data.get('features')) {
                if (!(rawFeature instanceof Map<String, Object>)) {
                    continue;
                }
                Map<String, Object> feature = (Map<String, Object>) rawFeature;
                String featureId = feature.get('id') == null ? null : String.valueOf(feature.get('id'));
                String autoWorkflowRequest = feature.get('autoWorkflowRequest') == null
                    ? null
                    : String.valueOf(feature.get('autoWorkflowRequest'));
                if (normalizeAutoWorkflowSanction(String.valueOf(feature.get('passportSanction'))) != expectedSanction) {
                    continue;
                }
                if (autoWorkflowRequest == null || !autoWorkflowRequest.equalsIgnoreCase('Y')
                    || String.isBlank(featureId) || startedFeatureIds.contains(featureId)
                    || !(feature.get('tasks') instanceof List<Object>)
                    || ((List<Object>) feature.get('tasks')).isEmpty()) {
                    continue;
                }

                List<Object> tasks = (List<Object>) feature.get('tasks');
                if (!(tasks[0] instanceof Map<String, Object>)) {
                    continue;
                }
                Map<String, Object> firstTask = (Map<String, Object>) tasks[0];
                if (String.isBlank(String.valueOf(firstTask.get('id')))
                    || !(firstTask.get('approvers') instanceof List<Object>)
                    || ((List<Object>) firstTask.get('approvers')).isEmpty()
                    || !(((List<Object>) firstTask.get('approvers'))[0] instanceof Map<String, Object>)) {
                    continue;
                }
                Map<String, Object> firstApprover = (Map<String, Object>) ((List<Object>) firstTask.get('approvers'))[0];
                if (String.isBlank(String.valueOf(firstApprover.get('id')))) {
                    continue;
                }

                Integer orderNumber = feature.get('orderNumber') == null
                    ? 2147483647
                    : Integer.valueOf(String.valueOf(feature.get('orderNumber')));
                DMT_CaseFeatureWrapper candidate = new DMT_CaseFeatureWrapper();
                candidate.featureId = featureId;
                candidate.featureName = feature.get('name') == null ? null : String.valueOf(feature.get('name'));
                candidate.passportSanction = feature.get('passportSanction') == null ? null : String.valueOf(feature.get('passportSanction'));
                candidate.featureOrder = orderNumber;
                candidate.externalLineid = data.get('opportunityId') == null ? null : String.valueOf(data.get('opportunityId'));
                candidate.approverId = String.valueOf(firstApprover.get('id'));
                candidate.taskId = String.valueOf(firstTask.get('id'));
                candidate.taskList = new List<Map<String, Object>>();
                for (Object taskObject : tasks) {
                    if (taskObject instanceof Map<String, Object>) {
                        candidate.taskList.add((Map<String, Object>) taskObject);
                    }
                }
                eligibleFeatures.add(candidate);
            }

            eligibleFeatures.sort();
            for (DMT_CaseFeatureWrapper feature : eligibleFeatures) {
                DMT_AsyncOrchestrator.enqueue(new DMT_StartApprovalCasePayload(
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
        }
    }

    public static void enqueueAutoWorkflowCases(Id lineId, String stage, Boolean ignored) {
        enqueueAutoWorkflowCases(lineId == null ? null : new Map<Id, String>{ lineId => stage }, false);
    }

    private static String autoWorkflowSanctionForStage(String stage) {
        if (stage == DMT_Constants.PROPOSAL) {
            return 'passport';
        }
        if (stage == DMT_Constants.APPROVAL) {
            return 'approval';
        }
        if (stage == DMT_Constants.READYTOCLOSE) {
            return 'readytoclose';
        }
        return null;
    }

    private static String normalizeAutoWorkflowSanction(String sanction) {
        return String.isBlank(sanction) ? null : sanction.toLowerCase().replaceAll('[^a-z0-9]', '');
    }

    public static void startApprovalCaseFromPayload(DMT_StartApprovalCasePayload payload) {
        if (payload == null || String.isBlank(payload.taskListJson)) {
            return;
        }

        if (System.isBatch()) {
            System.enqueueJob(new StartCaseQueueable(
                payload.externalLineId,
                payload.approverId,
                payload.taskId,
                payload.taskListJson,
                payload.featureId,
                payload.featureName,
                payload.comment,
                payload.passportSanction
            ));
            return;
        }

        Object rawTasks = JSON.deserializeUntyped(payload.taskListJson);
        if (!(rawTasks instanceof List<Object>)) {
            return;
        }
        List<Object> taskObjects = (List<Object>) rawTasks;
        List<Map<String, Object>> tasks = new List<Map<String, Object>>();
        for (Object rawTask : taskObjects) {
            if (rawTask instanceof Map<String, Object>) {
                tasks.add((Map<String, Object>) rawTask);
            }
        }
        if (!tasks.isEmpty()) {
            tasks.remove(0);
        }
        Map<String, Object> startResult = DMT_Passport_Handler.startCase(
            payload.externalLineId, payload.approverId, payload.taskId, tasks,
            payload.featureId, payload.featureName, payload.comment, payload.passportSanction
        );
        Boolean started = startResult != null
            && 'true'.equalsIgnoreCase(String.valueOf(startResult.get('success')));
        Boolean exceptionLogged = startResult != null
            && 'true'.equalsIgnoreCase(String.valueOf(startResult.get('exceptionLogged')));
        if (!started && !exceptionLogged) {
            String resultMessage = startResult == null ? 'startCase returned no result' : String.valueOf(startResult.get('message'));
            String diagnosticMessage = resultMessage
                + ' | featureId=' + payload.featureId
                + ', approverId=' + payload.approverId
                + ', taskId=' + payload.taskId
                + ', externalLineId=' + payload.externalLineId;
            DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(
                diagnosticMessage, '', 0, 'AutoWorkflowStartFailure',
                'DMT_Case_Steps_Controller', 'startApprovalCaseFromPayload', 'DMT', payload.externalLineId
            ));
        }
    }

    /**
     * CIBGLOBALD-4801 - Moves the Opportunity from Approval to Ready to close after its last approval Case closed
     * (processStartNextCaseApproval, called by Case_After_Trigger_Flow), only when every approval feature is approved
     * and no Passport feature required for Ready to close blocks it (DMT_Semaphore_Logic). Otherwise the Opportunity
     * stays in Approval and the user moves it from the path (dmt_custom_path_opp), which runs the same traffic light
     * check. Uses the Passport and Cases already loaded (no query). A failing check logs the error and does not move.
     */
    @TestVisible
    private static void moveStatusToReadyToClose(Passport__c passport, List<Case> contextCases) {
        if (passport == null || passport.Opportunity__c == null || passport.Opportunity__r?.StageName != DMT_Constants.APPROVAL) {
            return;
        }
        try {
            List<Object> features = DMT_Semaphore_Logic.getPassportFeatures(passport.DMT_Passport_Save__c);
            if (!DMT_Semaphore_Logic.areApprovalFeaturesApproved(features, contextCases)) {
                return;
            }
            List<String> blockingFeatureNames = DMT_Semaphore_Logic.getBlockingFeatureNames(features, contextCases, DMT_Constants.READYTOCLOSE);
            if (!blockingFeatureNames.isEmpty()) {
                System.debug(LoggingLevel.INFO, 'Opportunity ' + passport.Opportunity__c + ' stays in Approval, required features not met: ' + String.join(blockingFeatureNames, ', '));
                return;
            }
        } catch (Exception e) {
            DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(
                e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),
                'DMT_Case_Steps_Controller', 'moveStatusToReadyToClose', 'DMT', passport.Opportunity__c
            ));
            DMT_AsyncOrchestrator.flush();
            return;
        }
        update new Opportunity(Id = passport.Opportunity__c, StageName = DMT_Constants.READYTOCLOSE);
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

    @TestVisible
    private static Boolean isAutoWorkflowCaseForContext(
        Boolean isOpportunityContext,
        DMT_PassportLineWrapper contextPassport,
        Case caseRecord
    ) {
        if (isOpportunityContext != true || contextPassport == null || contextPassport.data == null
                || contextPassport.data.features == null || caseRecord == null
                || String.isBlank(caseRecord.DMT_Feature_Id__c)) {
            return false;
        }
        for (DMT_PassportLineWrapper.Feature passportFeature : contextPassport.data.features) {
            if (passportFeature != null && passportFeature.id == caseRecord.DMT_Feature_Id__c
                    && 'Y'.equalsIgnoreCase(passportFeature.autoWorkflowRequest)) {
                return true;
            }
        }
        return false;
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
        Map<String, Object> queueableResult = DMT_Passport_Handler.startCase(
            externalLineid, approverId, taskId, taskList, featureId, featureName, comment, passportSanction
        );

        System.debug('*** QUEUEABLE POST-EXECUTE RESULT: ' + JSON.serialize(queueableResult));

        if (queueableResult.get('success') == false || queueableResult.get('success') == 'false') {
            System.debug(LoggingLevel.ERROR, '*** QUEUEABLE SILENT FAILURE! Reason: ' + queueableResult.get('message'));
            if (queueableResult.get('exceptionLogged') != true && queueableResult.get('exceptionLogged') != 'true') {
                DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(
                    String.valueOf(queueableResult.get('message')) + ' | featureId=' + featureId
                        + ', approverId=' + approverId + ', taskId=' + taskId + ', externalLineId=' + externalLineid,
                    '', 0, 'AutoWorkflowStartFailure', 'DMT_Case_Steps_Controller', 'StartCaseQueueable', 'DMT', externalLineid
                ));
                DMT_AsyncOrchestrator.flush();
            }
        }
    }
  }

  /**
   * CIBGLOBALD-4801 - True when the record has a Passport and every approval feature with tasks is approved (latest Case
   * Finished, latest step Task Yes; DMT_Semaphore_Logic.areApprovalFeaturesApproved). Works for a DMT Line or an
   * Opportunity. 2 SOQL (Passport, Cases with their latest Task). A failing check logs the error and returns false.
   * Caller: DMT_Line_Helper.avoidPassingApproval (DMT_Line__c.DMT_Approval_Validation__c).
   * @param lineId DMT_Line__c Id (an Opportunity Id also works)
   */
  @AuraEnabled
  public static Boolean checkApprovalValidation(Id lineId) {
    if (lineId == null) {
      return false;
    }
    try {
      DMT_Semaphore_Logic.RecordFeatureData data = DMT_Semaphore_Logic.loadFeatureData(new Set<Id>{ lineId }).get(lineId);
      return data.hasPassport && DMT_Semaphore_Logic.areApprovalFeaturesApproved(data.features, data.cases);
    } catch (Exception e) {
      DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(
        e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),
        'DMT_Case_Steps_Controller', 'checkApprovalValidation', 'DMT', lineId
      ));
      DMT_AsyncOrchestrator.flush();
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
        @AuraEnabled
        public String tipoFuncOperacionProd;
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