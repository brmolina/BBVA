/**
 * Controller to manage massive task closure from the UI.
 *
 * Exposes @AuraEnabled methods to retrieve selected task information
 * and map it to a wrapper consumable by Aura/LWC.
 */
public with sharing class DMT_Massive_Task_Closure_Controller {

    /**
     * Retrieves the selected tasks for the massive closure process.
     *
     * Each selectionKeys item is expected in the following format:
     * CaseNumber_TaskId
     *
     * @param selectionKeys List of selection keys coming from the UI.
     * @return List of wrappers containing the required data for massive closure.
     */
    @AuraEnabled(cacheable=false)
    public static List<MassiveClosureWrapper> getTasksForMassiveClosure(List<String> selectionKeys) {
        List<MassiveClosureWrapper> results = new List<MassiveClosureWrapper>();
        Set<Id> taskIds = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();

        if (selectionKeys == null || selectionKeys.isEmpty()) {
            return results;
        }

        // Parse itemKey (CaseNumber_TaskId) to extract Task IDs
        for (String key : selectionKeys) {
            if (key != null && key.contains('_')) {
                taskIds.add((Id)key.substringAfter('_'));
            }
        }

        if (taskIds.isEmpty()) {
            return results;
        }

        // First pass: Query tasks to get Case IDs
        List<Task> selectedTasks = [
             SELECT Id, OwnerId, DMT_Task_Type__r.Name, Subject, DMT_Step_Result__c, WhatId, What.Name,
                   DMT_Task_Type__r.DMT_External_Id__c, DMT_Task_Type__r.DMT_NA_Flag__c,
                 DMT_Task_Type__r.DMT_No_Flag__c, DMT_Task_Type__r.DMT_Yes_Flag__c,
                 DMT_Task_Type__r.gf_task_ind_type__c, DMT_Committee_Label__c
            FROM Task
            WHERE Id IN :taskIds
            WITH USER_MODE
        ];

        for (Task t : selectedTasks) {
            if (t.WhatId != null && String.valueOf(t.WhatId).startsWith('500')) {
                caseIds.add(t.WhatId);
            }
        }

        Map<Id, Case> caseMap = new Map<Id, Case>();
        if (!caseIds.isEmpty()) {
            caseMap = new Map<Id, Case>([
                SELECT Id,
                       DMT_Closing_Tasks__c,
                       DMT_LineOpportunity__c,
                       DMT_Passport_Sanction__c,
                       opportunity_id__r.DMT_Opp_Id__c,
                       DMT_Line__r.Line_Id__c,
                       Account.Name
                FROM Case
                WHERE Id IN :caseIds
                WITH USER_MODE
            ]);
        }

        Set<Id> ownerIds = new Set<Id>();
        for (Task t : selectedTasks) {
            if (t.OwnerId != null) {
                ownerIds.add(t.OwnerId);
            }
        }

        Map<Id, Group> groupsById = new Map<Id, Group>();
        if (!ownerIds.isEmpty()) {
            groupsById = new Map<Id, Group>([
                SELECT Id, DeveloperName
                FROM Group
                WHERE Type = 'Queue'
                  AND Id IN :ownerIds
                WITH USER_MODE
            ]);
        }

        Set<String> groupNames = new Set<String>();
        for (Group g : groupsById.values()) {
            if (g.DeveloperName != null) {
                groupNames.add(g.DeveloperName);
            }
        }

        Map<String, DMT_Approver__c> approverByGroupName = new Map<String, DMT_Approver__c>();
        if (!groupNames.isEmpty()) {
            for (DMT_Approver__c approver : [
                SELECT DMT_Group__c, DMT_ApproverType__r.Name
                FROM DMT_Approver__c
                WHERE DMT_Group__c IN :groupNames
                WITH USER_MODE
            ]) {
                approverByGroupName.put(approver.DMT_Group__c, approver);
            }
        }

        for (Task t : selectedTasks) {
            String closingTasksJson = '';
            Case relatedCase;
            if (t.WhatId != null && caseMap.containsKey(t.WhatId)) {
                relatedCase = caseMap.get(t.WhatId);
                closingTasksJson = relatedCase.DMT_Closing_Tasks__c;
            }

            Boolean returnToProposalDisabled = true;
            if (relatedCase != null && t.DMT_Task_Type__r != null) {
                Boolean isTaskIndividualType = t.DMT_Task_Type__r.gf_task_ind_type__c == true;
                String lineOppType = relatedCase.DMT_LineOpportunity__c;

                if (lineOppType == 'L') {
                    returnToProposalDisabled = !isTaskIndividualType;
                } else {
                    String approverTypeName;
                    Group ownerGroup = groupsById.get(t.OwnerId);
                    if (ownerGroup != null) {
                        DMT_Approver__c approver = approverByGroupName.get(ownerGroup.DeveloperName);
                        if (approver != null && approver.DMT_ApproverType__r != null) {
                            approverTypeName = approver.DMT_ApproverType__r.Name;
                        }
                    }
                    Boolean isBusinessApprover = approverTypeName == 'Business';
                    returnToProposalDisabled = !(isBusinessApprover && isTaskIndividualType);
                }
            }

            results.add(new MassiveClosureWrapper(t, closingTasksJson, relatedCase, returnToProposalDisabled));
        }

        return results;
    }

    /**
     * Confirms the massive closure of all selected tasks and their associated cases.
     * Delegates to DMT_Massive_Task_Closure_Service for the full bulkified flow:
     * snapshot state → complete tasks → close cases → move ContentDocumentLinks →
     * update Opportunity Business Approver date (where applicable).
     *
     * @param payloadJson JSON string containing task payloads from the dmt_massive_task_closure_modal LWC.
     * @return ClosureResult with success flag and optional errorMessage.
     */
    @AuraEnabled(cacheable=false)
    public static DMT_Massive_Task_Closure_Service.ClosureResult confirmMassiveClosure(
            String payloadJson) {
        List<DMT_Massive_Task_Closure_Service.ClosurePayload> payloads =
            new List<DMT_Massive_Task_Closure_Service.ClosurePayload>();

        System.debug(LoggingLevel.INFO,
            'DMT_Massive_Task_Closure_Controller confirmMassiveClosure payloadJsonLength='
            + (payloadJson == null ? 0 : payloadJson.length()));

        if (!String.isBlank(payloadJson)) {
            try {
                payloads = (List<DMT_Massive_Task_Closure_Service.ClosurePayload>) JSON.deserialize(
                    payloadJson,
                    List<DMT_Massive_Task_Closure_Service.ClosurePayload>.class
                );
            } catch (Exception ex) {
                throw new AuraHandledException('Invalid payload format for massive closure: ' + ex.getMessage());
            }
        }

        System.debug(LoggingLevel.INFO,
            'DMT_Massive_Task_Closure_Controller confirmMassiveClosure payloadCount=' + payloads.size());

        return DMT_Massive_Task_Closure_Service.confirmMassiveClosure(payloads);
    }

    /**
     * Data wrapper to expose Task information to the presentation layer.
     */
    public class MassiveClosureWrapper {
        @AuraEnabled public Id taskId;
        @AuraEnabled public String taskName;
        @AuraEnabled public String result;
        @AuraEnabled public String comments;
        @AuraEnabled public String caseNumber;
        @AuraEnabled public Id caseId;
        @AuraEnabled public String externalId;
        @AuraEnabled public String naFlag;
        @AuraEnabled public String noFlag;
        @AuraEnabled public String yesFlag;
        @AuraEnabled public String closingTasksJson;
        @AuraEnabled public String lineOppId;
        @AuraEnabled public String client;
        @AuraEnabled public Boolean returnToProposalDisabled;
        @AuraEnabled public String committeeLabel;

        /**
         * Builds the wrapper from a Task record.
         *
         * @param t Source Task record.
         * @param closingTasks Selected case closing tasks JSON.
         * @param relatedCase Related case for additional display fields.
         */
        public MassiveClosureWrapper(Task t, String closingTasks, Case relatedCase, Boolean returnToProposalDisabledValue) {
            this.taskId = t.Id;
            this.taskName = (t.DMT_Task_Type__r != null && t.DMT_Task_Type__r.Name != null)
                ? t.DMT_Task_Type__r.Name
                : t.Subject;
            this.result = t.DMT_Step_Result__c;
            this.comments = ''; // Initialized empty for UI editing
            this.caseNumber = t.What != null ? t.What.Name : null;
            this.caseId = t.WhatId;

            if (t.DMT_Task_Type__r != null) {
                this.externalId = t.DMT_Task_Type__r.DMT_External_Id__c;
                this.naFlag = t.DMT_Task_Type__r.DMT_NA_Flag__c;
                this.noFlag = t.DMT_Task_Type__r.DMT_No_Flag__c;
                this.yesFlag = t.DMT_Task_Type__r.DMT_Yes_Flag__c;
            }

            if (relatedCase != null) {
                if (relatedCase.DMT_LineOpportunity__c == 'O') {
                    this.lineOppId = relatedCase.opportunity_id__r != null
                        ? relatedCase.opportunity_id__r.DMT_Opp_Id__c
                        : null;
                } else {
                    this.lineOppId = relatedCase.DMT_Line__r != null
                        ? relatedCase.DMT_Line__r.Line_Id__c
                        : null;
                }
                this.client = relatedCase.Account != null ? relatedCase.Account.Name : null;
            }

            this.closingTasksJson = closingTasks;
            this.returnToProposalDisabled = returnToProposalDisabledValue == true;
            this.committeeLabel = t.DMT_Committee_Label__c;
        }
    }
}