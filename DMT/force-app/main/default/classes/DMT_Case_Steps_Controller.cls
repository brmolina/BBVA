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
        Map<Id, Group> ownerIdToGroup = new Map<Id, Group>([SELECT Id, DeveloperName FROM Group WHERE Id IN :queueIds WITH SECURITY_ENFORCED]);
        
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
            if (cases.get(caseId) != null && cases.get(caseId).DMT_LineOpportunity__c != null && ((cases.get(caseId).DMT_LineOpportunity__c.equalsIgnoreCase('L') && cases.get(caseId).DMT_Line__r != null && cases.get(caseId).DMT_Line__r.Status__c != null && (cases.get(caseId).DMT_Line__r.Status__c.contains('Closed') || cases.get(caseId).DMT_Line__r.Status__c == DMT_Constants.READYTOCLOSE ) ) || (cases.get(caseId).DMT_LineOpportunity__c.equalsIgnoreCase('O') && cases.get(caseId).Opportunity_Id__r != null && cases.get(caseId).Opportunity_Id__r.StageName != null && (cases.get(caseId).Opportunity_Id__r.StageName.contains('Closed') || cases.get(caseId).Opportunity_Id__r.StageName == DMT_Constants.READYTOCLOSE ))) ) {
                parentStep.subitems.add(step);
                hasClosed = true;
                
            }else if(cases.get(caseId) != null && cases.get(caseId).Status.equalsIgnoreCase('Finished') ){
                parentStepFinished.subitems.add(step) ;
                hasFinished= true;
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
        
        List<Task> tasks = [SELECT Id, WhatId, Owner.Name, Status, LastModifiedBy.Name, DMT_Completed_Date_Time__c, DMT_UserClosedTask__c, DMT_UserClosedTask__r.Name, CreatedDate, CompletedDateTime, TOLABEL(DMT_Step_Type__c), DMT_Step_Result__c, Description, DMT_Task_Type__r.Name, DMT_Task_Type__r.DMT_Yes_Flag__c, DMT_Task_Type__r.DMT_No_Flag__c, DMT_Task_Type__r.DMT_NA_Flag__c FROM Task WHERE WhatId =: caseId and RecordType.DeveloperName = 'DMT_Step_Approval' WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC];
        return processTasksFromCases(tasks);
        
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
                    +'DMT_Task_Type__r.DMT_No_Flag__c, DMT_Task_Type__r.DMT_NA_Flag__c, DMT_UserClosedTask__c, DMT_UserClosedTask__r.Name, DMT_Completed_Date_Time__c FROM Task '
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
        return [
            SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.FileType, ContentDocument.ContentSize
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :taskId AND ContentDocument.LatestPublishedVersion.Is_Template_PDF__c=true WITH SECURITY_ENFORCED LIMIT 1
        ];
    }
    
    
    /**
     * Get files attached to the task
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getTaskFilesWithAttachments(Id taskId) {
        List<Map<String, Object>> allFiles = new List<Map<String, Object>>();
        
        // ContentDocuments relacionados al task
        for (ContentDocumentLink link : [SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.FileType, ContentDocument.ContentSize, 
                                        ContentDocument.LatestPublishedVersion.Is_Template_PDF__c, ContentDocument.CreatedDate
                                        FROM ContentDocumentLink WHERE LinkedEntityId = :taskId AND ContentDocument.FileType!='JSON' AND ContentDocument.FileType!='HTML' WITH SECURITY_ENFORCED ORDER BY ContentDocument.CreatedDate DESC
        ]) {
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
        for (Attachment att : [SELECT Id, Name, ContentType, CreatedDate, BodyLength FROM Attachment WHERE ParentId = :taskId WITH SECURITY_ENFORCED]) {
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
    
    
    @AuraEnabled(cacheable=false)
    public static String getBase64PdfData(String recordId, String type) {
        String fileData;
        List<ContentDocumentLink> cdl = [
            SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.FileType, ContentDocument.ContentSize,ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId AND ContentDocument.LatestPublishedVersion.Is_Template_PDF__c=true AND ContentDocument.FileType =: type WITH SECURITY_ENFORCED LIMIT 1
        ];
        
        List<ContentVersion> contentVersion = [
            SELECT Id,VersionData,ContentDocumentId,ContentDocument.FileType,ContentDocument.ContentSize,ContentDocument.Title
            FROM ContentVersion
            WHERE ContentDocumentId = :cdl[0].ContentDocumentId AND ContentDocument.FileType =: type  WITH SECURITY_ENFORCED
            ];
        if(type == 'PDF' && contentVersion[0].ContentDocument.FileType == 'PDF' && !contentVersion.isEmpty()){
            fileData = EncodingUtil.base64Encode(contentVersion[0].VersionData);
        }else if(type == 'JSON' && contentVersion[0].ContentDocument.FileType == 'JSON' && !contentVersion.isEmpty()){
            fileData = contentVersion[0].VersionData.toString();
        }else if(type == 'HTML' && contentVersion[0].ContentDocument.FileType == 'HTML' && !contentVersion.isEmpty()){
            fileData = contentVersion[0].VersionData.toString();
        }
        
        return fileData;
        
    }
    
    @AuraEnabled(cacheable=true)
    public static String getCaseDescription(Id recordId) {
        Task task = [SELECT Id, WhatId FROM Task WHERE Id = :recordId WITH SECURITY_ENFORCED LIMIT 1];
        
        Case c =[SELECT Id, Description FROM Case WHERE Id = :task.WhatId WITH SECURITY_ENFORCED LIMIT 1];
        
        return c.Description;
        
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
    
    if(newToProcess == null ){
      return;
    }
    
    Id lineId = newToProcess.DMT_Line__c;
    Id oppId  = newToProcess.opportunity_id__c;
    
    Boolean isLineContext = lineId != null;
    Boolean isOppContext  = oppId != null;
    
    if (!isLineContext && !isOppContext) {
      return;
    }
    
    Id contextId = isLineContext ? lineId : oppId;
    
    if(newToProcess.RecordTypeId == recordTypeCaseApproval && newToProcess.IsClosed == true && oldCaseToProcess.IsClosed == false && newToProcess.DMT_Passport_Sanction__c != null && newToProcess.DMT_Passport_Sanction__c.equalsIgnoreCase(DMT_Constants.APPROVAL)) {
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
        if(featureIterating.passportSanction=='approval'){
          approversIdList.add(featureIterating.tasks[0].approvers[0].Id);
          
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
    System.debug('******Mapa featureTypeByApprover: '+featureTypeByApprover); 
    Map<String, String> approverTypeMap = buildApproverTypeMap(featureTypeByApprover);
    System.debug('*******Mapa approverTypeMap: '+approverTypeMap);
    System.debug('**Lista listCaseFeatureWrappers 1'  + JSON.serializePretty(mapWrapperByLineorOpportunityId));
    System.debug('**mapFeaturesCasesByLineorOpportunityID'  + JSON.serializePretty(mapFeaturesCasesByLineorOpportunityID));
    
        //Se construye wrapper para encontrar las task siguiente y poder  generar el caso siguiente
        //Para eso se va a iterar feature, y para cada feature se va a identificar estado del caso, si lo hay y tipo de feature
    List<DMT_CaseFeatureWrapper> listCaseFeatureWrappers = new List<DMT_CaseFeatureWrapper>();
    for(  Id currentContextId  :mapWrapperByLineorOpportunityId.keySet()){
      for(DMT_PassportLineWrapper.feature iterateFeature :mapWrapperByLineorOpportunityId.get(currentContextId).data.features){
        if(iterateFeature.passportSanction=='approval'){
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
          cw.featureType = approverTypeMap.get(  iterateFeature.tasks[0].approvers[0].Id );
          cw.approverId = iterateFeature.tasks[0].approvers[0].Id;
          cw.taskId = iterateFeature.tasks[0].id;
          cw.myCase = mapFeaturesCasesByLineorOpportunityID.get(currentContextId).containsKey( iterateFeature.Id) ? mapFeaturesCasesByLineorOpportunityID.get(currentContextId).get(iterateFeature.Id): null;
          cw.caseStatus =   cw.myCase != null ? cw.myCase.Status : null;
          System.debug('**cw.myCase'  + JSON.serializePretty(cw.myCase));
          
          if(cw.myCase == null || (cw.myCase != null && cw.myCase.IsClosed == false) ){
            listCaseFeatureWrappers.add(cw);
          }
        }
      }
    }
    
    System.debug('**Lista listCaseFeatureWrappers 2'  + JSON.serializePretty(listCaseFeatureWrappers));
    List<DMT_CaseFeatureWrapper> listBussiness = new List<DMT_CaseFeatureWrapper>();
    List<DMT_CaseFeatureWrapper> listRisk = new List<DMT_CaseFeatureWrapper>();

    //Next feature:
    if(!listCaseFeatureWrappers.isEmpty()){
      
      listCaseFeatureWrappers.sort();
      for(DMT_CaseFeatureWrapper feature :listCaseFeatureWrappers){
        if(feature.featureType == 'Business'){
          listBussiness.add(feature);
        } else if(feature.featureType == 'Risk'){
          listRisk.add(feature);
        }
      }

      System.debug('**Lista Negocio'  + listBussiness);
      System.debug('**Lista Riesgo'  + listRisk);
      
      if (listBussiness.size() > 0) {
        DMT_CaseFeatureWrapper nextBusinessFeature = listBussiness[0];
        System.enqueueJob(new StartCaseQueueable(
          nextBusinessFeature.externalLineid,
        nextBusinessFeature.approverId,
        nextBusinessFeature.taskId,
        JSON.serialize(nextBusinessFeature.taskList),
        nextBusinessFeature.featureId,
        nextBusinessFeature.featureName,
        '',
        nextBusinessFeature.passportSanction
          ));
      } else if(listRisk.size()>0){
        DMT_CaseFeatureWrapper nextRiskFeature = listRisk[0];
        System.enqueueJob(new StartCaseQueueable(
          nextRiskFeature.externalLineid,
        nextRiskFeature.approverId,
        nextRiskFeature.taskId,
        JSON.serialize(nextRiskFeature.taskList),
        nextRiskFeature.featureId,
        nextRiskFeature.featureName,
        '',
        nextRiskFeature.passportSanction
          ));
      }
    }
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
        // Llamada a startCase ya en ejecución asíncrona
        DMT_Passport_Handler.startCase(externalLineid, approverId, taskId, taskList, featureId, featureName, comment, passportSanction);
      
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